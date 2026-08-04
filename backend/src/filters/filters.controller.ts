import { Body, Controller, Get, NotFoundException, Put, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { PrismaService } from '../prisma/prisma.service';
import { FiltersService } from './filters.service';
import { SetFilterDto } from './dto/set-filter.dto';

@UseGuards(JwtAuthGuard)
@Controller('filters')
export class FiltersController {
  constructor(
    private readonly filtersService: FiltersService,
    private readonly prisma: PrismaService,
  ) {}

  private async coupleIdOf(userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user?.coupleId) throw new NotFoundException('No perteneces a ninguna pareja todavía');
    return user.coupleId;
  }

  @Get('couple')
  async findForMyCouple(@CurrentUser() user: { userId: string }) {
    const coupleId = await this.coupleIdOf(user.userId);
    return this.filtersService.findForCouple(coupleId);
  }

  @Put('couple')
  async setForMyCouple(@CurrentUser() user: { userId: string }, @Body() dto: SetFilterDto) {
    const coupleId = await this.coupleIdOf(user.userId);
    return this.filtersService.upsertForCouple(coupleId, dto);
  }
}
