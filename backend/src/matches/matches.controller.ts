import { Controller, Delete, Get, NotFoundException, Param, Patch, Query, UseGuards } from '@nestjs/common';
import { MatchStatus } from '@prisma/client';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { MatchesService } from './matches.service';
import { PrismaService } from '../prisma/prisma.service';

@UseGuards(JwtAuthGuard)
@Controller('matches')
export class MatchesController {
  constructor(
    private readonly matchesService: MatchesService,
    private readonly prisma: PrismaService,
  ) {}

  private async coupleIdOf(userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user?.coupleId) throw new NotFoundException('No perteneces a ninguna pareja todavía');
    return user.coupleId;
  }

  @Get()
  async findAll(@CurrentUser() user: { userId: string }, @Query('status') status?: MatchStatus) {
    const coupleId = await this.coupleIdOf(user.userId);
    return this.matchesService.findForCouple(coupleId, status);
  }

  @Get('count')
  async count(@CurrentUser() user: { userId: string }) {
    const coupleId = await this.coupleIdOf(user.userId);
    return this.matchesService.countForCouple(coupleId);
  }

  @Patch(':id/watched')
  async markWatched(@CurrentUser() user: { userId: string }, @Param('id') id: string) {
    const coupleId = await this.coupleIdOf(user.userId);
    return this.matchesService.markWatched(coupleId, id);
  }

  @Delete(':id')
  async remove(@CurrentUser() user: { userId: string }, @Param('id') id: string) {
    const coupleId = await this.coupleIdOf(user.userId);
    return this.matchesService.remove(coupleId, id);
  }
}
