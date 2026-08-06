import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { MatchStatus } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class MatchesService {
  constructor(private readonly prisma: PrismaService) {}

  findForCouple(coupleId: string, status?: MatchStatus) {
    return this.prisma.match.findMany({
      where: { coupleId, ...(status ? { status } : {}) },
      include: { movie: { include: { availability: { include: { platform: true } } } } },
      orderBy: { createdAt: 'desc' },
    });
  }

  async countForCouple(coupleId: string) {
    const count = await this.prisma.match.count({ where: { coupleId } });
    return { count, maxReached: count >= 5 };
  }

  async markWatched(coupleId: string, matchId: string) {
    await this.assertBelongsToCouple(coupleId, matchId);
    return this.prisma.match.update({
      where: { id: matchId },
      data: { status: MatchStatus.WATCHED },
    });
  }

  async remove(coupleId: string, matchId: string) {
    await this.assertBelongsToCouple(coupleId, matchId);
    return this.prisma.match.delete({ where: { id: matchId } });
  }

  private async assertBelongsToCouple(coupleId: string, matchId: string) {
    const match = await this.prisma.match.findUnique({ where: { id: matchId } });
    if (!match) throw new NotFoundException('Match no encontrado');
    if (match.coupleId !== coupleId) throw new ForbiddenException();
    return match;
  }
}
