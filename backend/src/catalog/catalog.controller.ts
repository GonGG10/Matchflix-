import { Controller, Post, Query } from '@nestjs/common';
import { CatalogService } from './catalog.service';

@Controller('catalog')
export class CatalogController {
  constructor(private readonly catalogService: CatalogService) {}

  @Post('sync')
  async triggerSync(@Query('force') force?: string) {
    this.catalogService.syncCatalog(force === 'true')
      .then((result) => console.log(`Sync completed: ${result.titlesProcessed} titles`))
      .catch((err) => console.error(`Sync failed: ${err.message}`));
    return { status: 'accepted', message: 'Sync started in background.' };
  }

  @Post('repair-genres')
  async repairGenres() {
    try {
      const result = await this.catalogService.repairFallbackGenres();
      return { status: 'ok', repaired: result.repaired, total: result.total };
    } catch (err: any) {
      return { status: 'error', message: err.message };
    }
  }

  @Post('merge-duplicates')
  async mergeDuplicates() {
    try {
      const result = await this.catalogService.mergeDuplicateMovies();
      return { status: 'ok', merged: result.merged };
    } catch (err: any) {
      return { status: 'error', message: err.message };
    }
  }

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

  // Endpoint todo-en-uno: seed + repair + merge + dedup
  @Post('repair-all')
  async repairAll() {
    try {
      const seed = await this.catalogService.seedFallbackCatalog();
      const repair = await this.catalogService.repairFallbackGenres();
      const merge = await this.catalogService.mergeDuplicateMovies();
      const dedup = await this.catalogService.dedupCategories();
      return {
        status: 'ok',
        seeded: seed.count,
        repaired: repair.repaired,
        merged: merge.merged,
        deduped: dedup,
      };
    } catch (err: any) {
      return { status: 'error', message: err.message };
    }
  }
}
