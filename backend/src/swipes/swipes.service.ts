import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateSwipeDto } from './dto/create-swipe.dto';
import { MatchesGateway } from '../realtime/matches.gateway';

@Injectable()
export class SwipesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly matchesGateway: MatchesGateway,
  ) {}

  async create(userId: string, dto: CreateSwipeDto) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user?.coupleId) throw new NotFoundException('No perteneces a ninguna pareja todavía');

    let swipe;
    try {
      swipe = await this.prisma.swipe.create({
        data: {
          userId,
          coupleId: user.coupleId,
          movieId: dto.movieId,
          direction: dto.direction,
        },
      });
    } catch {
      // Ya existe swipe de este usuario para esta película (constraint única userId+movieId)
      throw new ConflictException('Ya has valorado esta película');
    }

    if (dto.direction === 'LIKE') {
      await this.checkForMatch(user.coupleId, dto.movieId);
    }

    return swipe;
  }

  // Si el otro miembro de la pareja también dio LIKE a la misma película,
  // se crea el Match y se notifica por WebSocket a la sala de la pareja.
  private async checkForMatch(coupleId: string, movieId: string) {
    const likesForMovie = await this.prisma.swipe.findMany({
      where: { coupleId, movieId, direction: 'LIKE' },
    });

    const couple = await this.prisma.couple.findUnique({
      where: { id: coupleId },
      include: { members: true },
    });
    if (!couple || couple.members.length < 2) return;

    const bothLiked = couple.members.every((member) =>
      likesForMovie.some((s) => s.userId === member.id),
    );
    if (!bothLiked) return;

    const existingMatch = await this.prisma.match.findUnique({
      where: { coupleId_movieId: { coupleId, movieId } },
    });
    if (existingMatch) return;

    const match = await this.prisma.match.create({
      data: { coupleId, movieId },
      include: { movie: true },
    });

    const matchCount = await this.prisma.match.count({ where: { coupleId } });
    const maxMatchesReached = matchCount >= 5;

    this.matchesGateway.notifyMatch(coupleId, {
      ...match,
      matchCount,
      maxMatchesReached,
    });
  }
}
