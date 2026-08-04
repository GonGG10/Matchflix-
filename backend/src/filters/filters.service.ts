import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { SetFilterDto } from './dto/set-filter.dto';

@Injectable()
export class FiltersService {
  constructor(private readonly prisma: PrismaService) {}

  findForCouple(coupleId: string) {
    return this.prisma.coupleFilter.findUnique({ where: { coupleId } });
  }

  upsertForCouple(coupleId: string, dto: SetFilterDto) {
    const data = {
      maxDuration: dto.maxDuration,
      minRating: dto.minRating,
      language: dto.language,
      year: dto.year,
      country: dto.country,
      mediaType: dto.mediaType,
      platformIds: dto.platformIds,
    };

    return this.prisma.coupleFilter.upsert({
      where: { coupleId },
      update: data,
      create: { coupleId, ...data },
    });
  }
}
