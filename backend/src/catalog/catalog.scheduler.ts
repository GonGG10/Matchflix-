import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { ConfigService } from '@nestjs/config';
import { CatalogService } from './catalog.service';
import { RoomsService } from '../rooms/rooms.service';

@Injectable()
export class CatalogScheduler {
  private readonly logger = new Logger(CatalogScheduler.name);

  constructor(
    private readonly catalogService: CatalogService,
    private readonly config: ConfigService,
  ) {}

  // Cron por defecto: "0 3 * * *" -> todos los días a las 03:00.
  // Configurable vía CATALOG_SYNC_CRON en el .env.
  @Cron(process.env.CATALOG_SYNC_CRON ?? '0 3 * * *')
  async handleDailySync() {
    this.logger.log('Ejecutando sincronización diaria programada del catálogo');
    try {
      await this.catalogService.syncCatalog();
    } catch (err) {
      this.logger.error('Fallo la sincronización de catálogo', err);
    }
  }
}
