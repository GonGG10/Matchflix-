import { Inject, Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';
import {
  RawCatalogTitle,
  STREAMING_CATALOG_PROVIDER,
  StreamingCatalogProvider,
} from './streaming-catalog-provider.interface';
import { buildFallbackCatalog } from './fallback-catalog.data';

function slugify(text: string): string {
  return text
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/\s+/g, '-');
}

const GENRE_MAP: Record<string, string> = {
  'Action': 'Acción', 'Action & Adventure': 'Acción y Aventura',
  'Adventure': 'Aventura', 'Animation': 'Animación', 'Anime': 'Anime',
  'Comedy': 'Comedia', 'Crime': 'Crimen', 'Documentary': 'Documental',
  'Drama': 'Drama', 'Family': 'Familia', 'Fantasy': 'Fantasía',
  'History': 'Historia', 'Horror': 'Terror', 'Music': 'Música',
  'Musical': 'Musical', 'Mystery': 'Misterio', 'Romance': 'Romance',
  'Science Fiction': 'Ciencia ficción', 'Sci-Fi': 'Ciencia ficción',
  'Thriller': 'Thriller', 'War': 'Guerra', 'Western': 'Western',
  'Kids': 'Infantil', 'Reality': 'Reality', 'Sport': 'Deporte',
  'Talk': 'Talk', 'News': 'Noticias', 'Game Show': 'Concursos',
  'Acción': 'Acción', 'Aventura': 'Aventura', 'Animación': 'Animación',
  'Comedia': 'Comedia', 'Crimen': 'Crimen', 'Documental': 'Documental',
  'Familia': 'Familia', 'Fantasía': 'Fantasía', 'Historia': 'Historia',
  'Terror': 'Terror', 'Música': 'Música', 'Misterio': 'Misterio',
  'Ciencia ficción': 'Ciencia ficción', 'Guerra': 'Guerra',
  'Infantil': 'Infantil', 'Deporte': 'Deporte', 'Noticias': 'Noticias',
  'Concursos': 'Concursos', 'Supernatural': 'Supernatural', 'Food': 'Food',
  'Sports': 'Deporte',
};

function normalizeGenre(name: string): string {
  return GENRE_MAP[name] ?? GENRE_MAP[name.trim()] ?? name;
}

@Injectable()
export class CatalogService {
  private readonly logger = new Logger(CatalogService.name);
  private lastLoginSyncAttempt: number | null = null;
  private readonly LOGIN_SYNC_THROTTLE_MS = 6 * 60 * 60 * 1000;
  private isSeeding = false;

  constructor(
    @Inject(STREAMING_CATALOG_PROVIDER)
    private readonly provider: StreamingCatalogProvider,
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
  ) {}

  async syncCatalog(force = false) {
    const country = this.config.get<string>('watchmode.country') ?? 'ES';
    this.logger.log(`Iniciando sincronización de catálogo (${country})`);

    const titles = await this.provider.fetchFullCatalog(country);

    if (titles.length === 0) {
      this.logger.warn('Watchmode devolvió 0 títulos; se mantiene el catálogo actual sin cambios.');
      return { titlesProcessed: 0, deleted: 0 };
    }

    for (const title of titles) {
      try {
        await this.upsertTitle(title);
      } catch (err: any) {
        this.logger.error(`Error al upsertar '${title.title}': ${err.message}`);
      }
    }

    await this.dedupCategories();

    return { titlesProcessed: titles.length, deleted: 0 };
  }

  async seedFallbackCatalog(): Promise<{ seeded: boolean; count: number }> {
    if (this.isSeeding) {
      this.logger.log('seedFallbackCatalog ya en curso, saltando...');
      return { seeded: false, count: 0 };
    }
    this.isSeeding = true;

    try {
      const country = this.config.get<string>('watchmode.country') ?? 'ES';
      const titles = buildFallbackCatalog(country);
      let errors = 0;

      for (const title of titles) {
        try {
          await this.upsertTitle(title);
        } catch (err: any) {
          errors++;
          this.logger.error(`Error al upsertar '${title.title}': ${err.message}`);
        }
      }

      const total = await this.prisma.movie.count();
      this.logger.log(`Catálogo de respaldo actualizado: ${titles.length} títulos (${errors} errores). Total en BD: ${total}.`);
      return { seeded: true, count: total };
    } finally {
      this.isSeeding = false;
    }
  }

  async repairFallbackGenres(): Promise<{ repaired: number; total: number }> {
    const country = this.config.get<string>('watchmode.country') ?? 'ES';
    const titles = buildFallbackCatalog(country);
    let repaired = 0;

    for (const title of titles) {
      try {
        const movie = await this.prisma.movie.findUnique({
          where: { externalId: title.externalId },
        });
        if (!movie) continue;

        await this.syncGenres(movie.id, title.genres);
        repaired++;
      } catch (err: any) {
        this.logger.error(`Error reparando géneros de '${title.title}': ${err.message}`);
      }
    }

    // También reparar películas de WatchMode que no tienen géneros:
    // buscar si hay una película del fallback con el mismo título y copiar sus géneros
    const moviesWithoutGenres = await this.prisma.movie.findMany({
      where: { categories: { none: {} } },
      include: { categories: true },
    });

    for (const m of moviesWithoutGenres) {
      // Buscar si existe una película del fallback con el mismo título
      const fallbackMatch = titles.find(
        (t) => t.title.toLowerCase() === m.title.toLowerCase() && t.genres.length > 0,
      );
      if (fallbackMatch) {
        try {
          await this.syncGenres(m.id, fallbackMatch.genres);
          repaired++;
          this.logger.log(`Géneros copiados del fallback a WatchMode movie '${m.title}'`);
        } catch (err: any) {
          this.logger.error(`Error copiando géneros a '${m.title}': ${err.message}`);
        }
      }
    }

    this.logger.log(`Reparación de géneros: ${repaired} películas reparadas.`);
    return { repaired, total: titles.length + moviesWithoutGenres.length };
  }

  // Fusiona películas duplicadas por título: si hay dos películas con el mismo
  // título (una de WatchMode y otra del fallback), mantiene una y elimina la otra,
  // moviendo los swipes y categorías a la superviviente.
  async mergeDuplicateMovies(): Promise<{ merged: number }> {
    const allMovies = await this.prisma.movie.findMany({
      select: { id: true, title: true, externalId: true },
    });

    // Agrupar por título (case-insensitive)
    const byTitle = new Map<string, typeof allMovies>();
    for (const m of allMovies) {
      const key = m.title.toLowerCase();
      if (!byTitle.has(key)) byTitle.set(key, []);
      byTitle.get(key)!.push(m);
    }

    let merged = 0;
    for (const [key, dupes] of byTitle) {
      if (dupes.length < 2) continue;

      // Preferir la película del fallback (tiene géneros garantizados)
      const fallback = dupes.find((d) => d.externalId.startsWith('fallback'));
      const survivor = fallback ?? dupes[0];
      const toDelete = dupes.filter((d) => d.id !== survivor.id);

      for (const d of toDelete) {
        try {
          // Mover swipes a la superviviente
          const swipes = await this.prisma.swipe.findMany({ where: { movieId: d.id } });
          for (const s of swipes) {
            await this.prisma.swipe.upsert({
              where: { userId_movieId: { userId: s.userId, movieId: survivor.id } },
              update: { direction: s.direction },
              create: { userId: s.userId, movieId: survivor.id, direction: s.direction, coupleId: s.coupleId },
            }).catch(() => {});
          }
          await this.prisma.swipe.deleteMany({ where: { movieId: d.id } });

          // Mover categorías a la superviviente
          const cats = await this.prisma.movieCategory.findMany({ where: { movieId: d.id } });
          for (const c of cats) {
            await this.prisma.movieCategory.upsert({
              where: { movieId_categoryId: { movieId: survivor.id, categoryId: c.categoryId } },
              update: {},
              create: { movieId: survivor.id, categoryId: c.categoryId },
            }).catch(() => {});
          }

          // Eliminar la película duplicada
          await this.prisma.movie.delete({ where: { id: d.id } });
          merged++;
          this.logger.log(`Película duplicada fusionada: '${survivor.title}' (eliminada ${d.externalId})`);
        } catch (err: any) {
          this.logger.error(`Error fusionando '${d.title}': ${err.message}`);
        }
      }
    }

    this.logger.log(`Fusión de duplicados: ${merged} películas eliminadas.`);
    return { merged };
  }

  async dedupCategories(): Promise<number> {
    const allCategories = await this.prisma.category.findMany();
    const bySlug = new Map(allCategories.map((c) => [c.slug, c]));

    let merged = 0;
    for (const [engName, espName] of Object.entries(GENRE_MAP)) {
      if (engName === espName) continue;

      const engSlug = slugify(engName);
      const espSlug = slugify(espName);
      const engCat = bySlug.get(engSlug);
      const espCat = bySlug.get(espSlug);

      if (!engCat) continue;

      try {
        if (espCat) {
          const movieLinks = await this.prisma.movieCategory.findMany({
            where: { categoryId: engCat.id },
          });
          for (const link of movieLinks) {
            await this.prisma.movieCategory.upsert({
              where: { movieId_categoryId: { movieId: link.movieId, categoryId: espCat.id } },
              update: {},
              create: { movieId: link.movieId, categoryId: espCat.id },
            });
          }
          await this.prisma.movieCategory.deleteMany({ where: { categoryId: engCat.id } });

          const coupleLinks = await this.prisma.coupleCategory.findMany({
            where: { categoryId: engCat.id },
          });
          for (const link of coupleLinks) {
            await this.prisma.coupleCategory.upsert({
              where: { coupleId_categoryId: { coupleId: link.coupleId, categoryId: espCat.id } },
              update: {},
              create: { coupleId: link.coupleId, categoryId: espCat.id },
            });
          }
          await this.prisma.coupleCategory.deleteMany({ where: { categoryId: engCat.id } });

          await this.prisma.category.delete({ where: { id: engCat.id } });
          merged++;
        } else {
          await this.prisma.category.update({
            where: { id: engCat.id },
            data: { name: espName, slug: espSlug },
          });
          merged++;
        }
      } catch (err: any) {
        this.logger.error(`Error al deduplicar categoría '${engName}': ${err.message}`);
      }
    }

    const compoundMap: Record<string, string> = {
      'Sci-Fi & Fantasy': 'Ciencia ficción y Fantasía',
      'War & Politics': 'Guerra y Política',
      'Action & Adventure': 'Acción y Aventura',
    };
    for (const [engName, espName] of Object.entries(compoundMap)) {
      const engCat = bySlug.get(slugify(engName));
      if (!engCat) continue;
      try {
        // Si la categoría española ya existe, fusionar como arriba
        const espCat = bySlug.get(slugify(espName));
        if (espCat) {
          const movieLinks = await this.prisma.movieCategory.findMany({
            where: { categoryId: engCat.id },
          });
          for (const link of movieLinks) {
            await this.prisma.movieCategory.upsert({
              where: { movieId_categoryId: { movieId: link.movieId, categoryId: espCat.id } },
              update: {},
              create: { movieId: link.movieId, categoryId: espCat.id },
            });
          }
          await this.prisma.movieCategory.deleteMany({ where: { categoryId: engCat.id } });
          await this.prisma.coupleCategory.deleteMany({ where: { categoryId: engCat.id } });
          await this.prisma.category.delete({ where: { id: engCat.id } });
          merged++;
        } else {
          await this.prisma.category.update({
            where: { id: engCat.id },
            data: { name: espName, slug: slugify(espName) },
          });
          merged++;
        }
      } catch (err: any) {
        this.logger.error(`Error al renombrar '${engName}': ${err.message}`);
      }
    }

    const remainingCats = await this.prisma.category.findMany({
      include: { _count: { select: { movies: true, couples: true } } },
    });
    const knownSlugs = new Set([
      ...Object.values(GENRE_MAP).map(s => slugify(s)),
      ...Object.values(compoundMap).map(s => slugify(s)),
    ]);
    const unmappedEnglish = remainingCats.filter((c) => {
      return !knownSlugs.has(c.slug) && c._count.movies === 0 && c._count.couples === 0;
    });
    for (const cat of unmappedEnglish) {
      try {
        await this.prisma.category.delete({ where: { id: cat.id } });
        merged++;
      } catch (_) {}
    }

    this.logger.log(`Deduplicación completa: ${merged} categorías consolidadas.`);
    return merged;
  }

  triggerLoginSync(): void {
    this.seedFallbackCatalog()
      .then(() => this.dedupCategories())
      .catch((err) =>
        this.logger.error('Fallo al actualizar el catálogo de respaldo', err),
      );

    const now = Date.now();
    if (
      this.lastLoginSyncAttempt !== null &&
      now - this.lastLoginSyncAttempt < this.LOGIN_SYNC_THROTTLE_MS
    ) {
      return;
    }
    this.lastLoginSyncAttempt = now;

    this.syncCatalog().catch((err) =>
      this.logger.warn(`Sincronización con Watchmode en login fallida: ${err.message}`),
    );
  }

  private async upsertTitle(title: RawCatalogTitle) {
    const movie = await this.prisma.movie.upsert({
      where: { externalId: title.externalId },
      update: {
        title: title.title,
        synopsis: title.synopsis,
        posterUrl: title.posterUrl,
        backdropUrl: title.backdropUrl,
        year: title.year,
        durationMinutes: title.durationMinutes,
        originalLanguage: title.originalLanguage,
        country: title.country,
        mediaType: title.mediaType,
        imdbRating: title.imdbRating,
        tmdbRating: title.tmdbRating,
      },
      create: {
        externalId: title.externalId,
        title: title.title,
        synopsis: title.synopsis,
        posterUrl: title.posterUrl,
        backdropUrl: title.backdropUrl,
        year: title.year,
        durationMinutes: title.durationMinutes,
        originalLanguage: title.originalLanguage,
        country: title.country,
        mediaType: title.mediaType,
        imdbRating: title.imdbRating,
        tmdbRating: title.tmdbRating,
      },
    });

    await this.syncGenres(movie.id, title.genres);
    await this.syncAvailability(movie.id, title.country, title.availability);
  }

  private async syncGenres(movieId: string, genreNames: string[]) {
    for (const rawName of genreNames) {
      try {
        const name = normalizeGenre(rawName);
        const category = await this.prisma.category.upsert({
          where: { slug: slugify(name) },
          update: {},
          create: { name, slug: slugify(name) },
        });
        await this.prisma.movieCategory.upsert({
          where: { movieId_categoryId: { movieId, categoryId: category.id } },
          update: {},
          create: { movieId, categoryId: category.id },
        });
      } catch (err: any) {
        this.logger.error(`syncGenres: Error con género '${rawName}' para película ${movieId}: ${err.message}`);
      }
    }
  }

  private async syncAvailability(movieId: string, country: string, availability: any[]) {
    if (!availability || availability.length === 0) return;

    for (const item of availability) {
      try {
        const platform = await this.prisma.platform.upsert({
          where: { slug: slugify(item.platformName) },
          update: {},
          create: { name: item.platformName, slug: slugify(item.platformName) },
        });
        await this.prisma.movieAvailability.upsert({
          where: { movieId_platformId_country: { movieId, platformId: platform.id, country } },
          update: {},
          create: { movieId, platformId: platform.id, country, deepLinkUrl: item.deepLinkUrl },
        });
      } catch (err: any) {
        this.logger.error(`syncAvailability: Error: ${err.message}`);
      }
    }
  }
}
