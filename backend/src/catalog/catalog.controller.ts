import { Controller, Post, Query } from '@nestjs/common';
import { CatalogService } from './catalog.service';

@Controller('catalog')
export class CatalogController {
  constructor(private readonly catalogService: CatalogService) {}

  @Post('sync')
  async triggerSync(@Query('force') force?: string) {
    // Return immediately — sync runs in background (takes ~3 min on free tier)
    this.catalogService.syncCatalog(force === 'true')
      .then((result) => console.log(`Sync completed: ${result.titlesProcessed} titles`))
      .catch((err) => console.error(`Sync failed: ${err.message}`));
    return { status: 'accepted', message: 'Sync started in background. Check catalog size in a few minutes.' };
  }

  // Repara las asociaciones de géneros para todas las películas del fallback.
  // Útil cuando una ejecución previa falló y dejó películas sin categorías.
  @Post('repair-genres')
  async repairGenres() {
    try {
      const result = await this.catalogService.repairFallbackGenres();
      return { status: 'ok', repaired: result.repaired, total: result.total };
    } catch (err: any) {
      return { status: 'error', message: err.message };
    }
  }

  // Fuerza el seed del fallback catalog + dedup de categorías
  @Post('seed')
  async seedFallback() {
    try {
      const result = await this.catalogService.seedFallbackCatalog();
      await this.catalogService.dedupCategories();
      return { status: 'ok', count: result.count };
    } catch (err: any) {
      return { status: 'error', message: err.message };
    }
  }
}
