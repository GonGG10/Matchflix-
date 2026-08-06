import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { RoomsService } from './rooms.service';

@Controller('rooms')
export class RoomsController {
  constructor(private readonly roomsService: RoomsService) {}

  @Post('create')
  createRoom() {
    return this.roomsService.createRoom();
  }

  @Post('join')
  joinRoom(@Body('inviteCode') inviteCode: string) {
    return this.roomsService.joinRoom(inviteCode);
  }

  @UseGuards(JwtAuthGuard)
  @Get('status')
  getRoomStatus(@CurrentUser() user: { userId: string }) {
    return this.roomsService.getRoomStatus(user.userId);
  }
}
