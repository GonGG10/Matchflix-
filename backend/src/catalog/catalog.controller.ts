import { Controller, Post, Query } from '@nestjs/common';
import { CatalogService } from './catalog.service';

// Endpoint manual para forzar una sincronización sin esperar al cron
// (útil en desarrollo o para un botón de administración).
@Controller('catalog')
export class CatalogController {
  constructor(private readonly catalogService: CatalogService) {}

  @Post('sync')
  async triggerSync(@Query('force') force?: string) {
    try {
      const result = await this.catalogService.syncCatalog(force === 'true');
      return { status: 'ok', titlesProcessed: result.titlesProcessed, deleted: result.deleted };
    } catch (err: any) {
      return { status: 'error', message: err.message };
    }
  }
}
