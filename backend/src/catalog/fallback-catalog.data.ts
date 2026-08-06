import { RawCatalogTitle } from './streaming-catalog-provider.interface';

// Catálogo de respaldo ampliado con películas y series reales y populares.
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
  // Películas clásicas y populares
  { title: 'El Padrino', year: 1972, synopsis: 'El patriarca de una familia de la mafia neoyorquina cede el control de su imperio a su reticente hijo.', durationMinutes: 175, mediaType: 'MOVIE', imdbRating: 9.2, genres: ['Drama', 'Crimen'], originalLanguage: 'en' },
  { title: 'Origen', year: 2010, synopsis: 'Un ladrón que roba secretos corporativos a través del uso de la tecnología de los sueños recibe una última misión.', durationMinutes: 148, mediaType: 'MOVIE', imdbRating: 8.8, genres: ['Ciencia ficción', 'Acción'], originalLanguage: 'en' },
  { title: 'Coco', year: 2017, synopsis: 'Un niño se adentra en la Tierra de los Muertos para descubrir la historia de su familia.', durationMinutes: 105, mediaType: 'MOVIE', imdbRating: 8.4, genres: ['Animación', 'Familia'], originalLanguage: 'en' },
  { title: 'Parásitos', year: 2019, synopsis: 'Una familia pobre se infiltra en la vida de una familia adinerada con consecuencias inesperadas.', durationMinutes: 132, mediaType: 'MOVIE', imdbRating: 8.5, genres: ['Drama', 'Thriller'], originalLanguage: 'ko' },
  { title: 'Interestelar', year: 2014, synopsis: 'Un grupo de exploradores viaja a través de un agujero de gusano en busca de un nuevo hogar para la humanidad.', durationMinutes: 169, mediaType: 'MOVIE', imdbRating: 8.6, genres: ['Ciencia ficción', 'Drama'], originalLanguage: 'en' },
  { title: 'La La Land', year: 2016, synopsis: 'Una actriz aspirante y un pianista de jazz se enamoran mientras persiguen sus sueños en Los Ángeles.', durationMinutes: 128, mediaType: 'MOVIE', imdbRating: 8.0, genres: ['Romance', 'Musical'], originalLanguage: 'en' },
  { title: 'Whiplash', year: 2014, synopsis: 'Un joven baterista de jazz es empujado al límite por un instructor implacable.', durationMinutes: 106, mediaType: 'MOVIE', imdbRating: 8.5, genres: ['Drama', 'Música'], originalLanguage: 'en' },
  { title: 'Toy Story', year: 1995, synopsis: 'Los juguetes de un niño cobran vida cuando los humanos no están mirando.', durationMinutes: 81, mediaType: 'MOVIE', imdbRating: 8.3, genres: ['Animación', 'Familia'], originalLanguage: 'en' },
  { title: 'El Caballero Oscuro', year: 2008, synopsis: 'Batman se enfrenta a un criminal caótico conocido como el Joker en Ciudad Gótica.', durationMinutes: 152, mediaType: 'MOVIE', imdbRating: 9.0, genres: ['Acción', 'Crimen'], originalLanguage: 'en' },
  { title: 'Pulp Fiction', year: 1994, synopsis: 'Las vidas de dos sicarios, un boxeador y una pareja de ladrones se entrelazan en Los Ángeles.', durationMinutes: 154, mediaType: 'MOVIE', imdbRating: 8.9, genres: ['Crimen', 'Drama'], originalLanguage: 'en' },
  { title: 'Titanic', year: 1997, synopsis: 'Un romance de clases opuestas florece a bordo del trasatlántico condenado a hundirse.', durationMinutes: 195, mediaType: 'MOVIE', imdbRating: 7.9, genres: ['Romance', 'Drama'], originalLanguage: 'en' },
  { title: 'Matrix', year: 1999, synopsis: 'Un programador descubre que la realidad que conoce es una simulación controlada por máquinas.', durationMinutes: 136, mediaType: 'MOVIE', imdbRating: 8.7, genres: ['Ciencia ficción', 'Acción'], originalLanguage: 'en' },
  { title: 'Zodiac', year: 2007, synopsis: 'Un caricaturista se obsesiona con encontrar al asesino en serie conocido como el Zodíaco.', durationMinutes: 157, mediaType: 'MOVIE', imdbRating: 7.7, genres: ['Thriller', 'Crimen'], originalLanguage: 'en' },
  { title: 'Your Name', year: 2016, synopsis: 'Dos adolescentes descubren que intercambian sus cuerpos misteriosamente y forjan un vínculo especial.', durationMinutes: 106, mediaType: 'MOVIE', imdbRating: 8.4, genres: ['Animación', 'Romance'], originalLanguage: 'ja' },
  { title: 'Jojo Rabbit', year: 2019, synopsis: 'Un niño alemán en la Alemania nazi descubre que su madre esconde a una niña judía en su casa.', durationMinutes: 108, mediaType: 'MOVIE', imdbRating: 7.9, genres: ['Comedia', 'Drama'], originalLanguage: 'en' },
  { title: 'Coraline', year: 2009, synopsis: 'Una niña descubre una puerta secreta a un mundo alternativo idéntico al suyo, pero mucho más siniestro.', durationMinutes: 100, mediaType: 'MOVIE', imdbRating: 7.7, genres: ['Animación', 'Terror'], originalLanguage: 'en' },
  { title: 'El Conjuro', year: 2013, synopsis: 'Dos investigadores paranormales ayudan a una familia aterrorizada por una presencia oscura en su granja.', durationMinutes: 112, mediaType: 'MOVIE', imdbRating: 7.5, genres: ['Terror'], originalLanguage: 'en' },
  { title: 'Cadena Perpetua', year: 1994, synopsis: 'Dos hombres encarcelados forjan un vínculo a lo largo de los años, encontrando consuelo y redención.', durationMinutes: 142, mediaType: 'MOVIE', imdbRating: 9.3, genres: ['Drama'], originalLanguage: 'en' },
  { title: 'Deadpool', year: 2016, synopsis: 'Un mercenario desfigurado se convierte en un antihéroe con un sentido del humor muy particular.', durationMinutes: 108, mediaType: 'MOVIE', imdbRating: 8.0, genres: ['Acción', 'Comedia'], originalLanguage: 'en' },
  { title: 'La Forma del Agua', year: 2017, synopsis: 'Una mujer muda forma una conexión inusual con una criatura anfibia cautiva en un laboratorio secreto.', durationMinutes: 123, mediaType: 'MOVIE', imdbRating: 7.3, genres: ['Fantasía', 'Romance'], originalLanguage: 'en' },
  { title: 'Rápidos y Furiosos', year: 2001, synopsis: 'Un policía encubierto se infiltra en el mundo de las carreras callejeras clandestinas.', durationMinutes: 106, mediaType: 'MOVIE', imdbRating: 6.8, genres: ['Acción'], originalLanguage: 'en' },
  { title: 'Bridget Jones', year: 2001, synopsis: 'Una treintañera londinense lleva un diario sobre sus torpes intentos de encontrar el amor.', durationMinutes: 97, mediaType: 'MOVIE', imdbRating: 6.7, genres: ['Comedia', 'Romance'], originalLanguage: 'en' },
  { title: 'Gladiator', year: 2000, synopsis: 'Un general romano traicionado se convierte en gladiador para vengar a su familia.', durationMinutes: 155, mediaType: 'MOVIE', imdbRating: 8.5, genres: ['Acción', 'Drama'], originalLanguage: 'en' },
  { title: 'El Señor de los Anillos: La Comunidad del Anillo', year: 2001, synopsis: 'Un joven hobbit emprende un viaje para destruir un anillo mágico antes de que caiga en manos equivocadas.', durationMinutes: 178, mediaType: 'MOVIE', imdbRating: 8.9, genres: ['Fantasía', 'Aventura'], originalLanguage: 'en' },
  { title: 'Avatar', year: 2009, synopsis: 'Un marine paralítico se infiltra en una raza alienígena pero se cuestiona su lealtad.', durationMinutes: 162, mediaType: 'MOVIE', imdbRating: 7.9, genres: ['Ciencia ficción', 'Aventura'], originalLanguage: 'en' },
  { title: 'Up', year: 2009, synopsis: 'Un anciano viudo ata globos a su casa para cumplir el sueño de aventura de su esposa.', durationMinutes: 96, mediaType: 'MOVIE', imdbRating: 8.3, genres: ['Animación', 'Familia'], originalLanguage: 'en' },
  { title: 'El Rey León', year: 1994, synopsis: 'Un joven león huye de su reino tras la muerte de su padre, pero debe volver para reclamar su trono.', durationMinutes: 88, mediaType: 'MOVIE', imdbRating: 8.5, genres: ['Animación', 'Aventura'], originalLanguage: 'en' },
  { title: 'Forrest Gump', year: 1994, synopsis: 'Un hombre con un corazón enorme vive momentos clave de la historia de EE.UU. sin darse cuenta.', durationMinutes: 142, mediaType: 'MOVIE', imdbRating: 8.8, genres: ['Drama', 'Comedia'], originalLanguage: 'en' },
  { title: 'Jurassic Park', year: 1993, synopsis: 'Un parque temático con dinosaurios clonados sale terriblemente mal.', durationMinutes: 127, mediaType: 'MOVIE', imdbRating: 8.2, genres: ['Ciencia ficción', 'Aventura'], originalLanguage: 'en' },
  { title: 'Spider-Man: Un Nuevo Universo', year: 2018, synopsis: 'Un adolescente con superpoderes se une a versiones alternativas de sí mismo de otros universos.', durationMinutes: 117, mediaType: 'MOVIE', imdbRating: 8.4, genres: ['Animación', 'Acción'], originalLanguage: 'en' },
  { title: 'Get Out', year: 2017, synopsis: 'Un joven negro descubre una conspiración perturbadora al visitar a la familia de su novia blanca.', durationMinutes: 104, mediaType: 'MOVIE', imdbRating: 7.7, genres: ['Terror', 'Misterio'], originalLanguage: 'en' },
  { title: 'Mad Max: Furia en la Carretera', year: 2015, synopsis: 'En un mundo post-apocalíptico, un fugitivo ayuda a una guerrera a rescatar a un grupo de mujeres.', durationMinutes: 120, mediaType: 'MOVIE', imdbRating: 8.1, genres: ['Acción', 'Ciencia ficción'], originalLanguage: 'en' },
  { title: 'La La Land', year: 2016, synopsis: 'Una actriz y un pianista de jazz se enamoran persiguiendo sus sueños en Los Ángeles.', durationMinutes: 128, mediaType: 'MOVIE', imdbRating: 8.0, genres: ['Romance', 'Musical'], originalLanguage: 'en' },
  { title: 'Shrek', year: 2001, synopsis: 'Un ogro descontento hace un trato con un lord para rescatar a una princesa a cambio de su tierra.', durationMinutes: 90, mediaType: 'MOVIE', imdbRating: 7.9, genres: ['Animación', 'Comedia'], originalLanguage: 'en' },
  { title: 'Los Increíbles', year: 2004, synopsis: 'Una familia de superhéroes retirados debe volver a la acción para salvar el mundo.', durationMinutes: 115, mediaType: 'MOVIE', imdbRating: 8.0, genres: ['Animación', 'Acción'], originalLanguage: 'en' },
  { title: 'Soul', year: 2020, synopsis: 'Un músico de jazz whose soul gets separated from his body must find his way back.', durationMinutes: 100, mediaType: 'MOVIE', imdbRating: 8.0, genres: ['Animación', 'Fantasía'], originalLanguage: 'en' },
  { title: 'Oppenheimer', year: 2023, synopsis: 'La historia del físico que dirigió el desarrollo de la bomba atómica durante la Segunda Guerra Mundial.', durationMinutes: 180, mediaType: 'MOVIE', imdbRating: 8.4, genres: ['Drama', 'Historia'], originalLanguage: 'en' },
  { title: 'Dune', year: 2021, synopsis: 'Un joven noble hereda un planeta desértico rico en el recurso más valioso del universo.', durationMinutes: 155, mediaType: 'MOVIE', imdbRating: 8.0, genres: ['Ciencia ficción', 'Aventura'], originalLanguage: 'en' },
  { title: 'Barbie', year: 2023, synopsis: 'Barbie descubre una crisis existencial que la lleva del mundo perfecto al mundo real.', durationMinutes: 114, mediaType: 'MOVIE', imdbRating: 6.8, genres: ['Comedia', 'Fantasía'], originalLanguage: 'en' },
  { title: 'Spider-Man: Cruzando el Multiverso', year: 2023, synopsis: 'Miles Morales viaja por el multiverso para salvar a cada realidad.', durationMinutes: 140, mediaType: 'MOVIE', imdbRating: 8.6, genres: ['Animación', 'Acción'], originalLanguage: 'en' },
  { title: 'El Cristal Encantado', year: 1982, synopsis: 'Un joven elfo emprende una búsqueda para reparar un cristal mágico y salvar su mundo.', durationMinutes: 93, mediaType: 'MOVIE', imdbRating: 7.1, genres: ['Fantasía', 'Aventura'], originalLanguage: 'en' },
  { title: 'Blade Runner 2049', year: 2017, synopsis: 'Un nuevo blade runner descubre un secreto que podría sumirir a la sociedad en el caos.', durationMinutes: 164, mediaType: 'MOVIE', imdbRating: 8.0, genres: ['Ciencia ficción', 'Misterio'], originalLanguage: 'en' },
  { title: 'El Laberinto del Fauno', year: 2006, synopsis: 'Una niña descubre un mundo mágico y oscuro tras la España franquista.', durationMinutes: 118, mediaType: 'MOVIE', imdbRating: 8.2, genres: ['Fantasía', 'Drama'], originalLanguage: 'es' },
  { title: 'Amélie', year: 2001, synopsis: 'Una camarera parisina decide mejorar la vida de quienes la rodean de formas ingeniosas.', durationMinutes: 122, mediaType: 'MOVIE', imdbRating: 8.3, genres: ['Comedia', 'Romance'], originalLanguage: 'fr' },
  { title: 'El Viaje de Chihiro', year: 2001, synopsis: 'Una niña queda atrapada en un mundo de espíritus y debe rescatar a sus padres convertidos en cerdos.', durationMinutes: 125, mediaType: 'MOVIE', imdbRating: 8.6, genres: ['Animación', 'Fantasía'], originalLanguage: 'ja' },
  // Series
  { title: 'Stranger Things', year: 2016, synopsis: 'Un grupo de niños se enfrenta a fuerzas sobrenaturales y experimentos gubernamentales secretos.', durationMinutes: 50, mediaType: 'SERIES', imdbRating: 8.7, genres: ['Ciencia ficción', 'Terror'], originalLanguage: 'en' },
  { title: 'Breaking Bad', year: 2008, synopsis: 'Un profesor de química se convierte en fabricante de metanfetamina tras un diagnóstico de cáncer.', durationMinutes: 47, mediaType: 'SERIES', imdbRating: 9.5, genres: ['Drama', 'Crimen'], originalLanguage: 'en' },
  { title: 'The Office', year: 2005, synopsis: 'Las cómicas y absurdas aventuras diarias de los empleados de una empresa de papel.', durationMinutes: 22, mediaType: 'SERIES', imdbRating: 9.0, genres: ['Comedia'], originalLanguage: 'en' },
  { title: 'Friends', year: 1994, synopsis: 'Seis amigos veinteañeros navegan el amor y la vida en la ciudad de Nueva York.', durationMinutes: 22, mediaType: 'SERIES', imdbRating: 8.9, genres: ['Comedia', 'Romance'], originalLanguage: 'en' },
  { title: 'Game of Thrones', year: 2011, synopsis: 'Noble familias luchan por el control del Trono de Hierro en un mundo de dragones y magia.', durationMinutes: 57, mediaType: 'SERIES', imdbRating: 9.2, genres: ['Fantasía', 'Drama'], originalLanguage: 'en' },
  { title: 'The Crown', year: 2016, synopsis: 'La vida de la Reina Isabel II y los eventos políticos y personales que marcaron su reinado.', durationMinutes: 55, mediaType: 'SERIES', imdbRating: 8.6, genres: ['Drama', 'Historia'], originalLanguage: 'en' },
  { title: 'Dark', year: 2017, synopsis: 'Una desaparición infantil desvela un misterio de viajes en el tiempo en un pueblo alemán.', durationMinutes: 45, mediaType: 'SERIES', imdbRating: 8.8, genres: ['Ciencia ficción', 'Misterio'], originalLanguage: 'de' },
  { title: 'Money Heist (La Casa de Papel)', year: 2017, synopsis: 'Un grupo de atracadores lleva a cabo el asalto más ambicioso de la historia.', durationMinutes: 70, mediaType: 'SERIES', imdbRating: 8.2, genres: ['Crimen', 'Thriller'], originalLanguage: 'es' },
  { title: 'The Mandalorian', year: 2019, synopsis: 'Un cazarrecompensas mandaloriano protege a una misteriosa criatura en los bordes de la galaxia.', durationMinutes: 40, mediaType: 'SERIES', imdbRating: 8.7, genres: ['Ciencia ficción', 'Aventura'], originalLanguage: 'en' },
  { title: 'Wednesday', year: 2022, synopsis: 'La hija de la familia Addams investiga una oleada de asesinatos en su escuela.', durationMinutes: 50, mediaType: 'SERIES', imdbRating: 8.1, genres: ['Comedia', 'Misterio'], originalLanguage: 'en' },
  { title: 'The Last of Us', year: 2023, synopsis: 'Un superviviente escolta a una niña que podría ser la clave de la curada de una pandemia.', durationMinutes: 60, mediaType: 'SERIES', imdbRating: 8.7, genres: ['Drama', 'Terror'], originalLanguage: 'en' },
  { title: 'Arcane', year: 2021, synopsis: 'Dos hermanas en ciudades rivales descubren el poder y la tragedia de la tecnología.', durationMinutes: 40, mediaType: 'SERIES', imdbRating: 9.0, genres: ['Animación', 'Acción'], originalLanguage: 'en' },
  { title: 'Severance', year: 2022, synopsis: 'Empleados con la memoria dividida entre su vida personal y laboral empiezan a cuestionar la verdad.', durationMinutes: 55, mediaType: 'SERIES', imdbRating: 8.7, genres: ['Ciencia ficción', 'Misterio'], originalLanguage: 'en' },
  { title: 'Bridgerton', year: 2020, synopsis: 'La familia Bridgerton navega la alta sociedad londinense en busca de amor y escándalo.', durationMinutes: 57, mediaType: 'SERIES', imdbRating: 7.3, genres: ['Romance', 'Drama'], originalLanguage: 'en' },
  { title: 'Black Mirror', year: 2011, synopsis: 'Episodios independientes exploran las consecuencias oscuras de la tecnología en la sociedad.', durationMinutes: 60, mediaType: 'SERIES', imdbRating: 8.8, genres: ['Ciencia ficción', 'Drama'], originalLanguage: 'en' },
  { title: 'Peaky Blinders', year: 2013, synopsis: 'Una familia de gánsteres en el Birmingham de posguerra ambiciona el poder a cualquier precio.', durationMinutes: 60, mediaType: 'SERIES', imdbRating: 8.8, genres: ['Crimen', 'Drama'], originalLanguage: 'en' },
  { title: 'Witcher', year: 2019, synopsis: 'Un cazador de monstruos solitario lucha por encontrar su lugar en un mundo donde las personas suelen ser más malvadas que las bestias.', durationMinutes: 50, mediaType: 'SERIES', imdbRating: 8.2, genres: ['Fantasía', 'Acción'], originalLanguage: 'en' },
  { title: 'You', year: 2018, synopsis: 'Un joven obsesivo utiliza la tecnología para acercarse a la mujer que ama, con consecuencias letales.', durationMinutes: 45, mediaType: 'SERIES', imdbRating: 7.7, genres: ['Drama', 'Thriller'], originalLanguage: 'en' },
  { title: 'Ozark', year: 2017, synopsis: 'Un asesor financiero se ve obligado a lavar dinero para un cartel en los Ozarks.', durationMinutes: 60, mediaType: 'SERIES', imdbRating: 8.5, genres: ['Crimen', 'Drama'], originalLanguage: 'en' },
  { title: 'The Boys', year: 2019, synopsis: 'Un grupo de personas normales lucha contra superhéroes corruptos que abusan de su poder.', durationMinutes: 60, mediaType: 'SERIES', imdbRating: 8.7, genres: ['Acción', 'Comedia'], originalLanguage: 'en' },
  { title: 'Arcane', year: 2021, synopsis: 'Dos hermanas en ciudades rivales descubren el poder y la tragedia de la tecnología.', durationMinutes: 40, mediaType: 'SERIES', imdbRating: 9.0, genres: ['Animación', 'Aventura'], originalLanguage: 'en' },
  { title: 'Ted Lasso', year: 2020, synopsis: 'Un entrenador de fútbol americano se muda a Inglaterra para dirigir un equipo de fútbol.', durationMinutes: 45, mediaType: 'SERIES', imdbRating: 8.8, genres: ['Comedia', 'Drama'], originalLanguage: 'en' },
  { title: 'The Bear', year: 2022, synopsis: 'Un joven chef de alta cocina regresa a Chicago para dirigir el restaurante de su familia.', durationMinutes: 30, mediaType: 'SERIES', imdbRating: 8.6, genres: ['Drama', 'Comedia'], originalLanguage: 'en' },
  { title: 'House of the Dragon', year: 2022, synopsis: 'La dinastía Targaryen se enfrenta a una guerra civil por la sucesión del Trono de Hierro.', durationMinutes: 60, mediaType: 'SERIES', imdbRating: 8.4, genres: ['Fantasía', 'Drama'], originalLanguage: 'en' },
  { title: 'Shogun', year: 2024, synopsis: 'Un navegante inglés se ve envuelto en las luchas de poder del Japón feudal.', durationMinutes: 60, mediaType: 'SERIES', imdbRating: 8.6, genres: ['Drama', 'Historia'], originalLanguage: 'en' },
];

export function buildFallbackCatalog(country: string): RawCatalogTitle[] {
  // Dedupe by title
  const seen = new Set<string>();
  const unique = DEFS.filter((d) => {
    if (seen.has(d.title)) return false;
    seen.add(d.title);
    return true;
  });

  return unique.map((d) => ({
    externalId: `fallback-${d.title.toLowerCase().replace(/[^a-z0-9]+/g, '-')}`,
    title: d.title,
    synopsis: d.synopsis,
    posterUrl: poster(d.title),
    backdropUrl: backdrop(d.title),
    year: d.year,
    durationMinutes: d.durationMinutes,
    originalLanguage: d.originalLanguage ?? 'en',
    country,
    mediaType: d.mediaType,
    imdbRating: d.imdbRating,
    tmdbRating: undefined,
    genres: d.genres,
    availability: [
      { platformName: 'Netflix' },
      { platformName: 'HBO Max' },
      { platformName: 'Amazon Prime Video' },
    ],
  }));
}
