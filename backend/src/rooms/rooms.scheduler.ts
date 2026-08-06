import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { RoomsService } from './rooms.service';

@Injectable()
export class RoomsScheduler {
  private readonly logger = new Logger(RoomsScheduler.name);

  constructor(private readonly rooms: RoomsService) {}

  @Cron('*/2 * * * *')
  async cleanupExpiredRooms() {
    try {
      await this.rooms.cleanupExpiredRooms();
    } catch (err) {
      this.logger.error('Error limpiando salas expiradas', err);
    }
  }
}
