import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class MoviesService {
  constructor(private readonly prisma: PrismaService) {}

  // Construye el WHERE de Prisma combinando las categorías/filtros de la pareja
  // con los filtros puntuales que llegan por query params.
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

  // Devuelve la siguiente película que el usuario aún no ha deslizado,
  // respetando las categorías y filtros de su pareja.
  async findNext(userId: string, coupleId: string, overrides: any) {
    const where = await this.buildWhere(coupleId, overrides);

    const alreadySwiped = await this.prisma.swipe.findMany({
      where: { userId },
      select: { movieId: true },
    });
    const swipedIds = alreadySwiped.map((s) => s.movieId);
    if (swipedIds.length > 0) {
      where.id = { notIn: swipedIds };
    }

    // Orden aleatorio para que la sesión de swipe no sea siempre igual.
    // A gran escala conviene precomputar un orden barajado (ver README - optimizaciones).
    const candidates = await this.prisma.movie.findMany({
      where,
      take: 20,
      include: { categories: { include: { category: true } }, availability: { include: { platform: true } } },
    });

    if (candidates.length === 0) return null;
    return candidates[Math.floor(Math.random() * candidates.length)];
  }

  async findMany(coupleId: string, overrides: any) {
    const where = await this.buildWhere(coupleId, overrides);
    return this.prisma.movie.findMany({
      where,
      take: 50,
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
