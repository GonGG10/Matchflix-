import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class CategoriesService {
  constructor(private readonly prisma: PrismaService) {}

  findAll() {
    return this.prisma.category.findMany({ orderBy: { name: 'asc' } });
  }

  async setForCouple(coupleId: string, categoryIds: string[]) {
    await this.prisma.coupleCategory.deleteMany({ where: { coupleId } });
    if (categoryIds.length === 0) return [];
    await this.prisma.coupleCategory.createMany({
      data: categoryIds.map((categoryId) => ({ coupleId, categoryId })),
      skipDuplicates: true,
    });
    return this.prisma.coupleCategory.findMany({
      where: { coupleId },
      include: { category: true },
    });
  }

  findForCouple(coupleId: string) {
    return this.prisma.coupleCategory.findMany({
      where: { coupleId },
      include: { category: true },
    });
  }
}
