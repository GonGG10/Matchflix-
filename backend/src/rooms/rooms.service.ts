import {
  BadRequestException,
  Injectable,
  NotFoundException,
  Logger,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { randomUUID } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import { CoupleStatus } from '@prisma/client';
import { CatalogService } from '../catalog/catalog.service';

const ROOM_TTL_MS = 15 * 60 * 1000; // 15 minutos
const SALT_ROUNDS = 12;

function generateInviteCode(): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let code = '';
  for (let i = 0; i < 6; i++) {
    code += chars[Math.floor(Math.random() * chars.length)];
  }
  return code;
}

function randomName(): string {
  const adjectives = ['Cinéfilo', 'Director', 'Crítico', 'Estrella', 'Artista', 'Guionista', 'Productor', 'Fanático'];
  const noun = adjectives[Math.floor(Math.random() * adjectives.length)];
  const num = Math.floor(Math.random() * 900 + 100);
  return `${noun}-${num}`;
}

@Injectable()
export class RoomsService {
  private readonly logger = new Logger(RoomsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
    private readonly catalogService: CatalogService,
  ) {}

  /** Crea una sala temporal: usuario anónimo + pareja PENDING. */
  async createRoom() {
    // Limpiar salas expiradas antes de crear una nueva
    await this.cleanupExpiredRooms();

    const email = `anon_${randomUUID()}@matchflix.temp`;
    const passwordHash = await bcrypt.hash(randomUUID(), SALT_ROUNDS);
    const displayName = randomName();

    const user = await this.prisma.user.create({
      data: { email, passwordHash, displayName },
    });

    let couple;
    for (let attempts = 0; attempts < 5 && !couple; attempts++) {
      try {
        couple = await this.prisma.couple.create({
          data: { inviteCode: generateInviteCode(), status: CoupleStatus.PENDING },
        });
      } catch { /* colisión de código, reintentar */ }
    }
    if (!couple) throw new BadRequestException('No se pudo crear la sala');

    await this.prisma.user.update({
      where: { id: user.id },
      data: { coupleId: couple.id },
    });

    // Sembrar catálogo si está vacío (no bloqueante)
    this.catalogService.triggerLoginSync();

    const accessToken = this.jwt.sign({ sub: user.id, email: user.email });
    const expiresAt = new Date(couple.createdAt.getTime() + ROOM_TTL_MS);

    this.logger.log(`Sala creada: ${couple.inviteCode}, expira: ${expiresAt.toISOString()}`);

    return {
      accessToken,
      inviteCode: couple.inviteCode,
      displayName,
      expiresAt: expiresAt.toISOString(),
    };
  }

  /** Une a un usuario anónimo a una sala existente. */
  async joinRoom(inviteCode: string) {
    await this.cleanupExpiredRooms();

    const email = `anon_${randomUUID()}@matchflix.temp`;
    const passwordHash = await bcrypt.hash(randomUUID(), SALT_ROUNDS);
    const displayName = randomName();

    const couple = await this.prisma.couple.findUnique({
      where: { inviteCode: inviteCode.toUpperCase() },
      include: { members: true },
    });

    if (!couple) throw new NotFoundException('Código de sala no válido');
    if (couple.members.length >= 2) {
      throw new BadRequestException('La sala ya está completa');
    }

    // Verificar que la sala no haya expirado
    const expiresAt = new Date(couple.createdAt.getTime() + ROOM_TTL_MS);
    if (new Date() > expiresAt) {
      await this.deleteCouple(couple.id);
      throw new BadRequestException('La sala ha expirado. Crea una nueva.');
    }

    const user = await this.prisma.user.create({
      data: {
        email,
        passwordHash,
        displayName,
        coupleId: couple.id,
      },
    });

    await this.prisma.couple.update({
      where: { id: couple.id },
      data: { status: CoupleStatus.ACTIVE },
    });

    const accessToken = this.jwt.sign({ sub: user.id, email: user.email });

    return {
      accessToken,
      inviteCode: couple.inviteCode,
      displayName,
      expiresAt: expiresAt.toISOString(),
      coupleStatus: 'ACTIVE' as const,
    };
  }

  /** Verifica el estado de la sala del usuario. */
  async getRoomStatus(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        couple: {
          include: { members: { select: { id: true, displayName: true } } },
        },
      },
    });

    if (!user?.couple) {
      return { hasRoom: false, status: 'NONE' };
    }

    const expiresAt = new Date(user.couple.createdAt.getTime() + ROOM_TTL_MS);
    const now = new Date();

    if (now > expiresAt) {
      await this.deleteCouple(user.couple.id);
      return { hasRoom: false, status: 'EXPIRED' };
    }

    const remainingMs = expiresAt.getTime() - now.getTime();
    const remainingMinutes = Math.floor(remainingMs / 60000);
    const remainingSeconds = Math.floor((remainingMs % 60000) / 1000);

    return {
      hasRoom: true,
      status: user.couple.status,
      inviteCode: user.couple.inviteCode,
      members: user.couple.members,
      expiresAt: expiresAt.toISOString(),
      remainingMs,
      remainingMinutes,
      remainingSeconds,
    };
  }

  /** Elimina salas expiradas (cron + on-demand). */
  async cleanupExpiredRooms() {
    const cutoff = new Date(Date.now() - ROOM_TTL_MS);
    const expired = await this.prisma.couple.findMany({
      where: { createdAt: { lt: cutoff } },
      include: { members: true },
    });

    for (const couple of expired) {
      await this.deleteCouple(couple.id);
    }

    if (expired.length > 0) {
      this.logger.log(`Limpieza: ${expired.length} salas expiradas eliminadas`);
    }

    return { cleaned: expired.length };
  }

  private async deleteCouple(coupleId: string) {
    // Borrar swipes, matches, categorías, filtros
    await this.prisma.swipe.deleteMany({ where: { coupleId } }).catch(() => {});
    await this.prisma.match.deleteMany({ where: { coupleId } }).catch(() => {});
    await this.prisma.coupleCategory.deleteMany({ where: { coupleId } }).catch(() => {});
    await this.prisma.coupleFilter.deleteMany({ where: { coupleId } }).catch(() => {});

    // Desvincular miembros
    await this.prisma.user.updateMany({
      where: { coupleId },
      data: { coupleId: null },
    }).catch(() => {});

    // Borrar usuarios anónimos
    await this.prisma.user.deleteMany({
      where: { email: { contains: '@matchflix.temp' }, coupleId: null },
    }).catch(() => {});

    // Borrar la pareja
    await this.prisma.couple.deleteMany({ where: { id: coupleId } }).catch(() => {});
  }
}
