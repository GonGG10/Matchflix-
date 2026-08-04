import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { SwipesService } from './swipes.service';
import { CreateSwipeDto } from './dto/create-swipe.dto';

@UseGuards(JwtAuthGuard)
@Controller('swipes')
export class SwipesController {
  constructor(private readonly swipesService: SwipesService) {}

  @Post()
  create(@CurrentUser() user: { userId: string }, @Body() dto: CreateSwipeDto) {
    return this.swipesService.create(user.userId, dto);
  }
}
