import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios from 'axios';
import {
  RawCatalogTitle,
  StreamingCatalogProvider,
} from '../streaming-catalog-provider.interface';

// Mapa de géneros en inglés → nombre canónico en español.
// Evita categorías duplicadas como "Action" y "Acción".
const GENRE_MAP: Record<string, string> = {
  'Action': 'Acción',
  'Action & Adventure': 'Acción y Aventura',
  'Adventure': 'Aventura',
  'Animation': 'Animación',
  'Anime': 'Anime',
  'Comedy': 'Comedia',
  'Crime': 'Crimen',
  'Documentary': 'Documental',
  'Drama': 'Drama',
  'Family': 'Familia',
  'Fantasy': 'Fantasía',
  'History': 'Historia',
  'Horror': 'Terror',
  'Music': 'Música',
  'Musical': 'Musical',
  'Mystery': 'Misterio',
  'Romance': 'Romance',
  'Science Fiction': 'Ciencia ficción',
  'Sci-Fi': 'Ciencia ficción',
  'Thriller': 'Thriller',
  'War': 'Guerra',
  'Western': 'Western',
  'Kids': 'Infantil',
  'Reality': 'Reality',
  'Sport': 'Deporte',
  'Talk': 'Talk',
  'News': 'Noticias',
  'Game Show': 'Concursos',
};

function normalizeGenre(name: string): string {
  return GENRE_MAP[name] ?? GENRE_MAP[name.trim()] ?? name;
}

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

    // Aumentado a 8 páginas de 50 = 400 títulos para tener un catálogo decente.
    // 1 petición list + 50 peticiones de detalle por página = ~408 peticiones total.
    // Con concurrencia 5 y pausa de 500ms entre lotes, completa en ~40s.
    // Rate limit de Watchmode free: 120 req/min → ~6.8s por lote de 5 → seguro.
    const MAX_PAGES = 8;
    const PAGE_SIZE = 50;
    const CONCURRENCY_LIMIT = 5;
    const BATCH_DELAY_MS = 500;

    const delay = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

    const titleIds: number[] = [];

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
        const status = err.response?.status;
        const detail = err.response?.data ?? err.message;
        this.logger.error(
          `Error al obtener la página ${page} de títulos en Watchmode: ${JSON.stringify(detail)}`,
        );
        if (status === 429 && page === 1) {
          this.logger.warn('Rate limit de Watchmode alcanzado. Esperando 60s para reintentar...');
          await delay(60000);
          try {
            const retryResponse = await axios.get(`${this.baseUrl}/list-titles/`, {
              params: {
                apiKey: this.apiKey,
                regions: country,
                types: 'movie,tv_series',
                limit: PAGE_SIZE,
                page,
              },
            });
            const titles = retryResponse.data?.titles ?? [];
            for (const t of titles) {
              if (t.id) titleIds.push(t.id);
            }
            if (titles.length < PAGE_SIZE) break;
            continue;
          } catch (retryErr: any) {
            this.logger.error(`Reintento también falló: ${JSON.stringify(retryErr.response?.data ?? retryErr.message)}`);
          }
        }
        if (page === 1) {
          throw new Error(`Watchmode list-titles falló: ${JSON.stringify(detail)}`);
        }
        break;
      }
    }

    this.logger.log(`Obtenidos ${titleIds.length} IDs de títulos. Descargando detalles...`);

    const results: RawCatalogTitle[] = [];

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
    // Normalizar géneros a español para evitar categorías duplicadas
    const genres = (raw.genre_names ?? []).map((g: string) => normalizeGenre(g));

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
      genres,
      availability: (raw.sources ?? [])
        .filter((s: any) => s.region === country)
        .map((s: any) => ({ platformName: s.name, deepLinkUrl: s.web_url })),
    };
  }
}
