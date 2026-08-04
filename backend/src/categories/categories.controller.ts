import { BadRequestException, Body, Controller, Get, Put, UseGuards } from '@nestjs/common';
import { IsArray, IsUUID } from 'class-validator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { CategoriesService } from './categories.service';
import { PrismaService } from '../prisma/prisma.service';

class SetCategoriesDto {
  @IsArray()
  @IsUUID('4', { each: true })
  categoryIds: string[];
}

@Controller('categories')
export class CategoriesController {
  constructor(
    private readonly categoriesService: CategoriesService,
    private readonly prisma: PrismaService,
  ) {}

  @Get()
  findAll() {
    return this.categoriesService.findAll();
  }

  @UseGuards(JwtAuthGuard)
  @Put('couple')
  async setForMyCouple(
    @CurrentUser() user: { userId: string },
    @Body() dto: SetCategoriesDto,
  ) {
    const dbUser = await this.prisma.user.findUnique({ where: { id: user.userId } });
    if (!dbUser || !dbUser.coupleId) {
      throw new BadRequestException('Usuario no pertenece a una pareja');
    }
    return this.categoriesService.setForCouple(dbUser.coupleId, dto.categoryIds);
  }

  @UseGuards(JwtAuthGuard)
  @Get('couple')
  async findForMyCouple(@CurrentUser() user: { userId: string }) {
    const dbUser = await this.prisma.user.findUnique({ where: { id: user.userId } });
    if (!dbUser || !dbUser.coupleId) {
      throw new BadRequestException('Usuario no pertenece a una pareja');
    }
    return this.categoriesService.findForCouple(dbUser.coupleId);
  }
}
