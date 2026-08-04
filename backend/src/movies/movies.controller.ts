import { Controller, Get, NotFoundException, Param, Query, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { MoviesService } from './movies.service';
import { MovieFilterDto } from './dto/movie-filter.dto';
import { PrismaService } from '../prisma/prisma.service';

@UseGuards(JwtAuthGuard)
@Controller('movies')
export class MoviesController {
  constructor(
    private readonly moviesService: MoviesService,
    private readonly prisma: PrismaService,
  ) {}

  private async coupleIdOf(userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user?.coupleId) throw new NotFoundException('No perteneces a ninguna pareja todavía');
    return user.coupleId;
  }

  @Get('next')
  async next(@CurrentUser() user: { userId: string }, @Query() filters: MovieFilterDto) {
    const coupleId = await this.coupleIdOf(user.userId);
    return this.moviesService.findNext(user.userId, coupleId, filters);
  }

  @Get()
  async findMany(@CurrentUser() user: { userId: string }, @Query() filters: MovieFilterDto) {
    const coupleId = await this.coupleIdOf(user.userId);
    return this.moviesService.findMany(coupleId, filters);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.moviesService.findOne(id);
  }
}
