import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios from 'axios';
import {
  RawCatalogTitle,
  StreamingCatalogProvider,
} from '../streaming-catalog-provider.interface';

// Implementación concreta contra la API de Watchmode.
// Esta es la ÚNICA clase de todo el backend que conoce la URL y la clave de
// Watchmode. La clave se lee de una variable de entorno y nunca sale de aquí.
@Injectable()
export class WatchmodeProvider implements StreamingCatalogProvider {
  private readonly logger = new Logger(WatchmodeProvider.name);
  private readonly apiKey: string;
  private readonly baseUrl: string;

  constructor(private readonly config: ConfigService) {
    this.apiKey = this.config.get<string>('watchmode.apiKey') ?? '';
    this.baseUrl = this.config.get<string>('watchmode.baseUrl') ?? 'https://api.watchmode.com/v1';
  }

  async fetchFullCatalog(country: string): Promise<RawCatalogTitle[]> {
    this.logger.log(`Descargando catálogo de Watchmode para ${country}...`);

    const MAX_PAGES = 10;
    const PAGE_SIZE = 250;
    const CONCURRENCY_LIMIT = 5;
    const BATCH_DELAY_MS = 200;

    const delay = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

    const titleIds: number[] = [];

    // Paso 1: Paginación para obtener listado de títulos (hasta 10 páginas de 250 títulos)
    for (let page = 1; page <= MAX_PAGES; page++) {
      try {
        const listResponse = await axios.get(`${this.baseUrl}/list-titles/`, {
          params: {
            apiKey: this.apiKey,
            regions: country,
            types: 'movie,tv_series',
            limit: PAGE_SIZE,
            page,
          },
        });

        const titles = listResponse.data?.titles ?? [];
        if (!Array.isArray(titles) || titles.length === 0) {
          break;
        }

        for (const t of titles) {
          if (t.id) {
            titleIds.push(t.id);
          }
        }

        if (titles.length < PAGE_SIZE) {
          break;
        }

        await delay(100);
      } catch (err: any) {
        this.logger.error(
          `Error al obtener la página ${page} de títulos en Watchmode: ${err.message}`,
        );
        break;
      }
    }

    this.logger.log(`Obtenidos ${titleIds.length} IDs de títulos. Descargando detalles...`);

    const results: RawCatalogTitle[] = [];

    // Paso 2: Peticiones paralelas por lotes de 5 con pequeña pausa entre lotes
    for (let i = 0; i < titleIds.length; i += CONCURRENCY_LIMIT) {
      const batchIds = titleIds.slice(i, i + CONCURRENCY_LIMIT);

      const batchPromises = batchIds.map(async (id) => {
        try {
          const detail = await axios.get(`${this.baseUrl}/title/${id}/details/`, {
            params: { apiKey: this.apiKey, append_to_response: 'sources' },
          });
          return this.mapToRawCatalogTitle(detail.data, country);
        } catch (err: any) {
          this.logger.warn(`No se pudo obtener el título ${id}: ${err.message}`);
          return null;
        }
      });

      const batchResults = await Promise.all(batchPromises);
      for (const res of batchResults) {
        if (res) {
          results.push(res);
        }
      }

      if (i + CONCURRENCY_LIMIT < titleIds.length) {
        await delay(BATCH_DELAY_MS);
      }
    }

    this.logger.log(`Catálogo de Watchmode completado con ${results.length} títulos.`);
    return results;
  }

  private mapToRawCatalogTitle(raw: any, country: string): RawCatalogTitle {
    return {
      externalId: String(raw.id),
      title: raw.title,
      synopsis: raw.plot_overview,
      posterUrl: raw.poster,
      backdropUrl: raw.backdrop,
      year: raw.year,
      durationMinutes: raw.runtime_minutes,
      originalLanguage: raw.original_language,
      country,
      mediaType: raw.type === 'tv_series' ? 'SERIES' : 'MOVIE',
      imdbRating: raw.user_rating,
      tmdbRating: raw.critic_score ? raw.critic_score / 10 : undefined,
      genres: raw.genre_names ?? [],
      availability: (raw.sources ?? [])
        .filter((s: any) => s.region === country)
        .map((s: any) => ({ platformName: s.name, deepLinkUrl: s.web_url })),
    };
  }
}
