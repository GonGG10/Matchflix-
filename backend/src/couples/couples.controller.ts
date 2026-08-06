import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { CouplesService } from './couples.service';
import { JoinCoupleDto } from './dto/join-couple.dto';

@UseGuards(JwtAuthGuard)
@Controller('couples')
export class CouplesController {
  constructor(private readonly couplesService: CouplesService) {}

  @Post()
  create(@CurrentUser() user: { userId: string }) {
    return this.couplesService.create(user.userId);
  }

  @Post('join')
  join(@CurrentUser() user: { userId: string }, @Body() dto: JoinCoupleDto) {
    return this.couplesService.join(user.userId, dto.inviteCode);
  }

  @Get('me')
  findMine(@CurrentUser() user: { userId: string }) {
    return this.couplesService.findMine(user.userId);
  }

  @Post('reset-session')
  resetSession(@CurrentUser() user: { userId: string }) {
    return this.couplesService.resetSession(user.userId);
  }

  @Post('reset-swipes')
  resetSwipes(@CurrentUser() user: { userId: string }) {
    return this.couplesService.resetSwipes(user.userId);
  }
}
