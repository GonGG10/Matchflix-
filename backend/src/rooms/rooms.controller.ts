import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { IsString } from 'class-validator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { RoomsService } from './rooms.service';

class JoinRoomDto {
  @IsString()
  inviteCode!: string;
}

@Controller('rooms')
export class RoomsController {
  constructor(private readonly roomsService: RoomsService) {}

  @Post('create')
  createRoom() {
    return this.roomsService.createRoom();
  }

  @Post('join')
  joinRoom(@Body() dto: JoinRoomDto) {
    return this.roomsService.joinRoom(dto.inviteCode);
  }

  @UseGuards(JwtAuthGuard)
  @Get('status')
  getRoomStatus(@CurrentUser() user: { userId: string }) {
    return this.roomsService.getRoomStatus(user.userId);
  }
}
