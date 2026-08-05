import { RawCatalogTitle } from './streaming-catalog-provider.interface';

// Catálogo de respaldo con películas y series reales.
// No depende de Watchmode ni de ninguna clave de API: así la app siempre
// tiene contenido con el que probar el swipe y el matching, aunque la
// sincronización con el proveedor externo falle o aún no esté configurada.
// Los pósters usan un servicio de imágenes sin clave (picsum.photos con
// semilla fija por título, para que cada película tenga siempre la misma
// imagen).
function poster(seed: string): string {
  return `https://picsum.photos/seed/${encodeURIComponent(seed)}/500/750`;
}
function backdrop(seed: string): string {
  return `https://picsum.photos/seed/${encodeURIComponent(seed)}-bg/1280/720`;
}

interface FallbackDef {
  title: string;
  year: number;
  synopsis: string;
  durationMinutes?: number;
  mediaType: 'MOVIE' | 'SERIES';
  imdbRating?: number;
  genres: string[];
  originalLanguage?: string;
}

const DEFS: FallbackDef[] = [
  { title: 'El Padrino', year: 1972, synopsis: 'El patriarca de una familia de la mafia neoyorquina cede el control de su imperio a su reticente hijo.', durationMinutes: 175, mediaType: 'MOVIE', imdbRating: 9.2, genres: ['Drama', 'Crimen'] },
  { title: 'Origen', year: 2010, synopsis: 'Un ladrón que roba secretos corporativos a través del uso de la tecnología de los sueños recibe una última misión.', durationMinutes: 148, mediaType: 'MOVIE', imdbRating: 8.8, genres: ['Ciencia ficción', 'Acción'] },
  { title: 'Coco', year: 2017, synopsis: 'Un niño se adentra en la Tierra de los Muertos para descubrir la historia de su familia.', durationMinutes: 105, mediaType: 'MOVIE', imdbRating: 8.4, genres: ['Animación', 'Familia'] },
  { title: 'Parásitos', year: 2019, synopsis: 'Una familia pobre se infiltra en la vida de una familia adinerada con consecuencias inesperadas.', durationMinutes: 132, mediaType: 'MOVIE', imdbRating: 8.5, genres: ['Drama', 'Thriller'] },
  { title: 'Interestelar', year: 2014, synopsis: 'Un grupo de exploradores viaja a través de un agujero de gusano en busca de un nuevo hogar para la humanidad.', durationMinutes: 169, mediaType: 'MOVIE', imdbRating: 8.6, genres: ['Ciencia ficción', 'Drama'] },
  { title: 'La La Land', year: 2016, synopsis: 'Una actriz aspirante y un pianista de jazz se enamoran mientras persiguen sus sueños en Los Ángeles.', durationMinutes: 128, mediaType: 'MOVIE', imdbRating: 8.0, genres: ['Romance', 'Musical'] },
  { title: 'Whiplash', year: 2014, synopsis: 'Un joven baterista de jazz es empujado al límite por un instructor implacable.', durationMinutes: 106, mediaType: 'MOVIE', imdbRating: 8.5, genres: ['Drama', 'Música'] },
  { title: 'Toy Story', year: 1995, synopsis: 'Los juguetes de un niño cobran vida cuando los humanos no están mirando.', durationMinutes: 81, mediaType: 'MOVIE', imdbRating: 8.3, genres: ['Animación', 'Familia'] },
  { title: 'El Caballero Oscuro', year: 2008, synopsis: 'Batman se enfrenta a un criminal caótico conocido como el Joker en Ciudad Gótica.', durationMinutes: 152, mediaType: 'MOVIE', imdbRating: 9.0, genres: ['Acción', 'Crimen'] },
  { title: 'Pulp Fiction', year: 1994, synopsis: 'Las vidas de dos sicarios, un boxeador y una pareja de ladrones se entrelazan en Los Ángeles.', durationMinutes: 154, mediaType: 'MOVIE', imdbRating: 8.9, genres: ['Crimen', 'Drama'] },
  { title: 'Titanic', year: 1997, synopsis: 'Un romance de clases opuestas florece a bordo del trasatlántico condenado a hundirse.', durationMinutes: 195, mediaType: 'MOVIE', imdbRating: 7.9, genres: ['Romance', 'Drama'] },
  { title: 'Matrix', year: 1999, synopsis: 'Un programador descubre que la realidad que conoce es una simulación controlada por máquinas.', durationMinutes: 136, mediaType: 'MOVIE', imdbRating: 8.7, genres: ['Ciencia ficción', 'Acción'] },
  { title: 'Zodiac', year: 2007, synopsis: 'Un caricaturista se obsesiona con encontrar al asesino en serie conocido como el Zodíaco.', durationMinutes: 157, mediaType: 'MOVIE', imdbRating: 7.7, genres: ['Thriller', 'Crimen'] },
  { title: 'Your Name', year: 2016, synopsis: 'Dos adolescentes descubren que intercambian sus cuerpos misteriosamente y forjan un vínculo especial.', durationMinutes: 106, mediaType: 'MOVIE', imdbRating: 8.4, genres: ['Animación', 'Romance'] },
  { title: 'Jojo Rabbit', year: 2019, synopsis: 'Un niño alemán en la Alemania nazi descubre que su madre esconde a una niña judía en su casa.', durationMinutes: 108, mediaType: 'MOVIE', imdbRating: 7.9, genres: ['Comedia', 'Drama'] },
  { title: 'Coraline', year: 2009, synopsis: 'Una niña descubre una puerta secreta a un mundo alternativo idéntico al suyo, pero mucho más siniestro.', durationMinutes: 100, mediaType: 'MOVIE', imdbRating: 7.7, genres: ['Animación', 'Terror'] },
  { title: 'El Conjuro', year: 2013, synopsis: 'Dos investigadores paranormales ayudan a una familia aterrorizada por una presencia oscura en su granja.', durationMinutes: 112, mediaType: 'MOVIE', imdbRating: 7.5, genres: ['Terror'] },
  { title: 'Cadena Perpetua', year: 1994, synopsis: 'Dos hombres encarcelados forjan un vínculo a lo largo de los años, encontrando consuelo y redención.', durationMinutes: 142, mediaType: 'MOVIE', imdbRating: 9.3, genres: ['Drama'] },
  { title: 'Deadpool', year: 2016, synopsis: 'Un mercenario desfigurado se convierte en un antihéroe con un sentido del humor muy particular.', durationMinutes: 108, mediaType: 'MOVIE', imdbRating: 8.0, genres: ['Acción', 'Comedia'] },
  { title: 'La Forma del Agua', year: 2017, synopsis: 'Una mujer muda forma una conexión inusual con una criatura anfibia cautiva en un laboratorio secreto.', durationMinutes: 123, mediaType: 'MOVIE', imdbRating: 7.3, genres: ['Fantasía', 'Romance'] },
  { title: 'Rápidos y Furiosos', year: 2001, synopsis: 'Un policía encubierto se infiltra en el mundo de las carreras callejeras clandestinas.', durationMinutes: 106, mediaType: 'MOVIE', imdbRating: 6.8, genres: ['Acción'] },
  { title: 'Bridget Jones', year: 2001, synopsis: 'Una treintañera londinense lleva un diario sobre sus torpes intentos de encontrar el amor.', durationMinutes: 97, mediaType: 'MOVIE', imdbRating: 6.7, genres: ['Comedia', 'Romance'] },
  { title: 'Stranger Things', year: 2016, synopsis: 'Un grupo de niños se enfrenta a fuerzas sobrenaturales y experimentos gubernamentales secretos en su pueblo.', durationMinutes: 50, mediaType: 'SERIES', imdbRating: 8.7, genres: ['Ciencia ficción', 'Terror'] },
  { title: 'Breaking Bad', year: 2008, synopsis: 'Un profesor de química se convierte en fabricante de metanfetamina tras un diagnóstico de cáncer.', durationMinutes: 47, mediaType: 'SERIES', imdbRating: 9.5, genres: ['Drama', 'Crimen'] },
  { title: 'The Office', year: 2005, synopsis: 'Las cómicas y absurdas aventuras diarias de los empleados de una empresa de papel.', durationMinutes: 22, mediaType: 'SERIES', imdbRating: 9.0, genres: ['Comedia'] },
  { title: 'Friends', year: 1994, synopsis: 'Seis amigos veinteañeros navegan el amor y la vida en la ciudad de Nueva York.', durationMinutes: 22, mediaType: 'SERIES', imdbRating: 8.9, genres: ['Comedia', 'Romance'] },
];

export function buildFallbackCatalog(country: string): RawCatalogTitle[] {
  return DEFS.map((d) => ({
    externalId: `fallback-${d.title.toLowerCase().replace(/[^a-z0-9]+/g, '-')}`,
    title: d.title,
    synopsis: d.synopsis,
    posterUrl: poster(d.title),
    backdropUrl: backdrop(d.title),
    year: d.year,
    durationMinutes: d.durationMinutes,
    originalLanguage: 'es',
    country,
    mediaType: d.mediaType,
    imdbRating: d.imdbRating,
    tmdbRating: undefined,
    genres: d.genres,
    availability: [
      { platformName: 'Netflix' },
      { platformName: 'HBO Max' },
    ],
  }));
}
