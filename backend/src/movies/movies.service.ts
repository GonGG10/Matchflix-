import { Injectable, Logger } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class MoviesService {
  private readonly logger = new Logger(MoviesService.name);
  constructor(private readonly prisma: PrismaService) {}

  private async buildWhere(coupleId: string, overrides: Partial<{
    maxDuration: number;
    minRating: number;
    language: string;
    year: number;
    country: string;
    mediaType: 'MOVIE' | 'SERIES';
    platformIds: string[];
  }>): Promise<Prisma.MovieWhereInput> {
    const [coupleCategories, coupleFilter] = await Promise.all([
      this.prisma.coupleCategory.findMany({ where: { coupleId } }),
      this.prisma.coupleFilter.findUnique({ where: { coupleId } }),
    ]);

    const categoryIds = coupleCategories.map((c) => c.categoryId);
    const maxDuration = overrides.maxDuration ?? coupleFilter?.maxDuration ?? undefined;
    const minRating = overrides.minRating ?? coupleFilter?.minRating ?? undefined;
    const language = overrides.language ?? coupleFilter?.language ?? undefined;
    const year = overrides.year ?? coupleFilter?.year ?? undefined;
    const country = overrides.country ?? coupleFilter?.country ?? undefined;
    const mediaType = overrides.mediaType ?? coupleFilter?.mediaType ?? undefined;
    const platformIds = overrides.platformIds ?? coupleFilter?.platformIds ?? undefined;

    const where: Prisma.MovieWhereInput = {};

    if (categoryIds.length > 0) {
      where.categories = { some: { categoryId: { in: categoryIds } } };
    }
    if (maxDuration) where.durationMinutes = { lte: maxDuration };
    if (minRating) where.imdbRating = { gte: minRating };
    if (language) where.originalLanguage = language;
    if (year) where.year = year;
    if (country) where.country = country;
    if (mediaType) where.mediaType = mediaType;
    if (platformIds && platformIds.length > 0) {
      where.availability = { some: { platformId: { in: platformIds } } };
    }

    return where;
  }

  async findNext(userId: string, coupleId: string, overrides: any, excludeIds: string[] = []) {
    const where = await this.buildWhere(coupleId, overrides);

    // Excluir SOLO los swipes del usuario actual, NO los de su pareja.
    // Esto permite que ambos miembros vean las mismas películas y puedan
    // hacer match cuando ambos dan LIKE a la misma película.
    // Los matches ya creados sí se excluyen para ambos (vía coupleId).
    const [userSwipes, matchedMovies] = await Promise.all([
      this.prisma.swipe.findMany({
        where: { userId },
        select: { movieId: true },
      }),
      this.prisma.match.findMany({
        where: { coupleId },
        select: { movieId: true },
      }),
    ]);

    const swipedIds = userSwipes.map((s) => s.movieId);
    const matchedIds = matchedMovies.map((m) => m.movieId);
    // Combinar todas las exclusiones: swipes del usuario + matches de la pareja + frontend excludeIds
    const allExclude = [...new Set([...swipedIds, ...matchedIds, ...excludeIds])];
    if (allExclude.length > 0) {
      where.id = { notIn: allExclude };
    }

    this.logger.debug(
      `findNext: user=${userId}, userSwipes=${swipedIds.length}, ` +
      `matched=${matchedIds.length}, frontendExclude=${excludeIds.length}, ` +
      `total_exclude=${allExclude.length}, mediaType=${where.mediaType ?? 'ANY'}`
    );

    // take: 5000 para traer TODOS los candidatos y luego elegir uno al azar.
    // Si usamos take: 20, podríamos perdernos películas que cumplen el filtro
    // pero que quedan después de las primeras 20.
    const candidates = await this.prisma.movie.findMany({
      where,
      take: 5000,
      include: { categories: { include: { category: true } }, availability: { include: { platform: true } } },
    });

    if (candidates.length === 0) {
      this.logger.debug(`findNext: no hay candidatos después de excluir ${allExclude.length} películas`);
      return null;
    }

    this.logger.debug(`findNext: ${candidates.length} candidatos disponibles, eligiendo uno al azar`);
    return candidates[Math.floor(Math.random() * candidates.length)];
  }

  async findMany(coupleId: string, overrides: any) {
    const where = await this.buildWhere(coupleId, overrides);
    return this.prisma.movie.findMany({
      where,
      take: 5000,
      include: { categories: { include: { category: true } }, availability: { include: { platform: true } } },
    });
  }

  findOne(id: string) {
    return this.prisma.movie.findUnique({
      where: { id },
      include: { categories: { include: { category: true } }, availability: { include: { platform: true } } },
    });
  }
}
