import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async findById(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { id },
      select: {
        id: true,
        email: true,
        displayName: true,
        avatarUrl: true,
        coupleId: true,
        createdAt: true,
        couple: { select: { status: true } },
      },
    });
    if (!user) throw new NotFoundException('Usuario no encontrado');
    const { couple, ...rest } = user;
    return {
      ...rest,
      coupleStatus: couple?.status ?? null,
    };
  }
}
