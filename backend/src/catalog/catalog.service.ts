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


// Mapa de géneros en inglés → español para evitar categorías duplicadas.
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
};

function normalizeGenre(name: string): string {
  return GENRE_MAP[name] ?? GENRE_MAP[name.trim()] ?? name;
}

@Injectable()
export class CatalogService {
  private readonly logger = new Logger(CatalogService.name);
  // Throttle en memoria para no golpear la API de Watchmode en cada login.
  private lastLoginSyncAttempt: number | null = null;
  private readonly LOGIN_SYNC_THROTTLE_MS = 6 * 60 * 60 * 1000; // 6 horas

  constructor(
    @Inject(STREAMING_CATALOG_PROVIDER)
    private readonly provider: StreamingCatalogProvider,
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
  ) {}

  // Tarea completa de sincronización: descarga el catálogo del proveedor y
  // hace upsert de películas, plataformas, disponibilidad y géneros.
  // Las películas que ya no aparecen en el catálogo del proveedor se eliminan.
  async syncCatalog() {
    const country = this.config.get<string>('watchmode.country') ?? 'ES';
    this.logger.log(`Iniciando sincronización de catálogo (${country})`);

    const titles = await this.provider.fetchFullCatalog(country);

    if (titles.length === 0) {
      // Salvaguarda: si el proveedor no devuelve nada, no borramos el
      // catálogo existente (evita dejar la app sin contenido por un fallo
      // puntual o una respuesta vacía inesperada).
      this.logger.warn('Watchmode devolvió 0 títulos; se mantiene el catálogo actual sin cambios.');
      return { titlesProcessed: 0, deleted: 0 };
    }

    const seenExternalIds: string[] = [];

    for (const title of titles) {
      seenExternalIds.push(title.externalId);
      await this.upsertTitle(title);
    }

    // Solo eliminamos películas antiguas de Watchmode si la nueva sincronización
    // trajo un número razonable de títulos (al menos 20). Si Watchmode devolvió
    // muy pocos (fallo parcial, rate limit, etc.), conservamos todo para no
    // vaciar el catálogo.
    let deletedCount = 0;
    if (titles.length >= 20) {
      const staleMovies = await this.prisma.movie.findMany({
        where: { externalId: { notIn: seenExternalIds } },
        select: { id: true, externalId: true },
      });
      const idsToDelete = staleMovies
        .filter((m) => !m.externalId.startsWith('fallback-'))
        .map((m) => m.id);
      if (idsToDelete.length > 0) {
        const result = await this.prisma.movie.deleteMany({
          where: { id: { in: idsToDelete } },
        });
        deletedCount = result.count;
      }
    } else {
      this.logger.warn(
        `Solo ${titles.length} títulos de Watchmode — no se elimina el catálogo existente.`,
      );
    }

    this.logger.log(
      `Sincronización completa: ${titles.length} títulos de Watchmode procesados, ${deletedCount} eliminados (catálogo de respaldo preservado).`,
    );

    return { titlesProcessed: titles.length, deleted: deletedCount };
  }

  // Inserta un catálogo de respaldo (películas y series reales, con pósters
  // que no dependen de ninguna clave de API) si la tabla Movie está vacía.
  // Garantiza que siempre haya contenido con el que probar la app, incluso
  // si Watchmode no está configurado todavía o la clave no es válida.
  async seedFallbackCatalogIfEmpty(): Promise<{ seeded: boolean; count: number }> {
    const existing = await this.prisma.movie.count();
    if (existing > 0) return { seeded: false, count: existing };

    const country = this.config.get<string>('watchmode.country') ?? 'ES';
    const titles = buildFallbackCatalog(country);
    for (const title of titles) {
      await this.upsertTitle(title);
    }
    this.logger.log(`Catálogo de respaldo insertado: ${titles.length} títulos.`);
    return { seeded: true, count: titles.length };
  }

  // Se llama en cada login/registro. No bloquea la respuesta al usuario:
  // 1. Si no hay ninguna película todavía, siembra el catálogo de respaldo
  //    al momento (rápido, sin llamadas externas) para que la app nunca
  //    aparezca vacía.
  // 2. Además, como mucho una vez cada 6 horas, intenta sincronizar de
  //    verdad con Watchmode en segundo plano (si falla, solo queda en logs).
  triggerLoginSync(): void {
    this.seedFallbackCatalogIfEmpty().catch((err) =>
      this.logger.error('Fallo al sembrar el catálogo de respaldo', err),
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
      this.logger.warn(`Sincronización con Watchmode en login fallida (se mantiene el catálogo actual): ${err.message}`),
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
    }
  }

  private async syncAvailability(
    movieId: string,
    country: string,
    availability: { platformName: string; deepLinkUrl?: string }[],
  ) {
    await this.prisma.movieAvailability.deleteMany({ where: { movieId, country } });
    for (const item of availability) {
      const platform = await this.prisma.platform.upsert({
        where: { slug: slugify(item.platformName) },
        update: {},
        create: { name: item.platformName, slug: slugify(item.platformName) },
      });
      await this.prisma.movieAvailability.upsert({
        where: { movieId_platformId_country: { movieId, platformId: platform.id, country } },
        update: { deepLinkUrl: item.deepLinkUrl },
        create: { movieId, platformId: platform.id, country, deepLinkUrl: item.deepLinkUrl },
      });
    }
  }
}
