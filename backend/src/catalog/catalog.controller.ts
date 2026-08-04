import { Controller, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CatalogService } from './catalog.service';

// Endpoint manual para forzar una sincronización sin esperar al cron
// (útil en desarrollo o para un botón de administración).
@UseGuards(JwtAuthGuard)
@Controller('catalog')
export class CatalogController {
  constructor(private readonly catalogService: CatalogService) {}

  @Post('sync')
  async triggerSync() {
    try {
      const result = await this.catalogService.syncCatalog();
      return { status: 'ok', ...result };
    } catch (err: any) {
      return { status: 'error', message: err.message };
    }
  }
}
