import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class PlatformsService {
  constructor(private readonly prisma: PrismaService) {}

  findAll() {
    return this.prisma.platform.findMany({ orderBy: { name: 'asc' } });
  }
}
