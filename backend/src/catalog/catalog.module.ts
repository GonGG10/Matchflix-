import { Module } from '@nestjs/common';
import { CatalogService } from './catalog.service';
import { CatalogScheduler } from './catalog.scheduler';
import { WatchmodeProvider } from './providers/watchmode.provider';
import { STREAMING_CATALOG_PROVIDER } from './streaming-catalog-provider.interface';
import { CatalogController } from './catalog.controller';

@Module({
  controllers: [CatalogController],
  providers: [
    CatalogService,
    CatalogScheduler,
    WatchmodeProvider,
    // El resto de la app inyecta STREAMING_CATALOG_PROVIDER, nunca WatchmodeProvider
    // directamente. Cambiar de proveedor es cambiar esta línea.
    { provide: STREAMING_CATALOG_PROVIDER, useExisting: WatchmodeProvider },
  ],
  exports: [CatalogService],
})
export class CatalogModule {}
