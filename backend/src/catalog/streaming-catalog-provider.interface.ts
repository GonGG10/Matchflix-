// Capa de abstracción del proveedor de catálogo.
// Hoy la implementa Watchmode (ver providers/watchmode.provider.ts), pero
// el resto del sistema nunca depende de Watchmode directamente: solo de esta
// interfaz. Así, el día de mañana se puede añadir JustWatch u otra fuente
// (o combinar varias) sin tocar CatalogService, el scheduler ni la app móvil.
export interface RawCatalogTitle {
  externalId: string;
  title: string;
  synopsis?: string;
  posterUrl?: string;
  backdropUrl?: string;
  year?: number;
  durationMinutes?: number;
  originalLanguage?: string;
  country: string;
  mediaType: 'MOVIE' | 'SERIES';
  imdbRating?: number;
  tmdbRating?: number;
  genres: string[]; // nombres de género tal como vienen del proveedor
  availability: {
    platformName: string;
    deepLinkUrl?: string;
  }[];
}

export interface StreamingCatalogProvider {
  /** Devuelve el catálogo completo disponible para un país. */
  fetchFullCatalog(country: string): Promise<RawCatalogTitle[]>;
}

export const STREAMING_CATALOG_PROVIDER = 'STREAMING_CATALOG_PROVIDER';
