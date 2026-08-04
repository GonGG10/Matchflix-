import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CoupleStatus } from '@prisma/client';

function generateInviteCode(): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // sin caracteres ambiguos
  let code = '';
  for (let i = 0; i < 6; i++) {
    code += chars[Math.floor(Math.random() * chars.length)];
  }
  return code;
}

@Injectable()
export class CouplesService {
  constructor(private readonly prisma: PrismaService) {}

  async create(userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (user?.coupleId) {
      throw new ConflictException('Ya perteneces a una pareja');
    }

    // Reintenta si hay colisión de código (extremadamente improbable, pero es correcto)
    let couple;
    for (let attempts = 0; attempts < 5 && !couple; attempts++) {
      try {
        couple = await this.prisma.couple.create({
          data: { inviteCode: generateInviteCode(), status: CoupleStatus.PENDING },
        });
      } catch {
        // colisión de código único, reintentar
      }
    }
    if (!couple) throw new BadRequestException('No se pudo generar la pareja, inténtalo de nuevo');

    await this.prisma.user.update({
      where: { id: userId },
      data: { coupleId: couple.id },
    });

    return couple;
  }

  async join(userId: string, inviteCode: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (user?.coupleId) {
      throw new ConflictException('Ya perteneces a una pareja');
    }

    const couple = await this.prisma.couple.findUnique({
      where: { inviteCode: inviteCode.toUpperCase() },
      include: { members: true },
    });
    if (!couple) throw new NotFoundException('Código de invitación no válido');
    if (couple.members.length >= 2) {
      throw new ConflictException('Esa pareja ya tiene dos miembros');
    }

    await this.prisma.user.update({
      where: { id: userId },
      data: { coupleId: couple.id },
    });

    return this.prisma.couple.update({
      where: { id: couple.id },
      data: { status: CoupleStatus.ACTIVE },
      include: { members: { select: { id: true, displayName: true, email: true } } },
    });
  }

  async findMine(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        couple: {
          include: { members: { select: { id: true, displayName: true, email: true } } },
        },
      },
    });
    if (!user?.couple) throw new NotFoundException('No perteneces a ninguna pareja todavía');
    return user.couple;
  }
}
