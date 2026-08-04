import { Inject, Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';
import {
  RawCatalogTitle,
  STREAMING_CATALOG_PROVIDER,
  StreamingCatalogProvider,
} from './streaming-catalog-provider.interface';

function slugify(text: string): string {
  return text
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/\s+/g, '-');
}

@Injectable()
export class CatalogService {
  private readonly logger = new Logger(CatalogService.name);

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
    const seenExternalIds: string[] = [];

    for (const title of titles) {
      seenExternalIds.push(title.externalId);
      await this.upsertTitle(title);
    }

    const deleted = await this.prisma.movie.deleteMany({
      where: { externalId: { notIn: seenExternalIds } },
    });

    this.logger.log(
      `Sincronización completa: ${titles.length} títulos procesados, ${deleted.count} eliminados.`,
    );

    return { titlesProcessed: titles.length, deleted: deleted.count };
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
    for (const name of genreNames) {
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
