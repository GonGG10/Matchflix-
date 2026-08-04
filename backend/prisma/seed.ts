// Seed inicial: categorías (géneros) y plataformas de streaming.
// Ejecutar con: npm run prisma:seed
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

const CATEGORIES = [
  'Acción', 'Comedia', 'Terror', 'Drama', 'Thriller', 'Romántica',
  'Ciencia ficción', 'Fantasía', 'Documental', 'Animación', 'Anime',
  'Misterio', 'Musical', 'Histórica', 'Crimen', 'Western', 'Bélica',
  'Aventura', 'Infantil', 'Biografía',
];

const PLATFORMS = [
  { name: 'Netflix', slug: 'netflix' },
  { name: 'Prime Video', slug: 'prime-video' },
  { name: 'Disney+', slug: 'disney-plus' },
  { name: 'Max', slug: 'max' },
  { name: 'Movistar Plus+', slug: 'movistar-plus' },
  { name: 'SkyShowtime', slug: 'skyshowtime' },
  { name: 'Apple TV+', slug: 'apple-tv-plus' },
  { name: 'Filmin', slug: 'filmin' },
];

function slugify(text: string): string {
  return text
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/\s+/g, '-');
}

async function main() {
  for (const name of CATEGORIES) {
    await prisma.category.upsert({
      where: { slug: slugify(name) },
      update: {},
      create: { name, slug: slugify(name) },
    });
  }

  for (const platform of PLATFORMS) {
    await prisma.platform.upsert({
      where: { slug: platform.slug },
      update: {},
      create: platform,
    });
  }

  console.log(`Seed completo: ${CATEGORIES.length} categorías, ${PLATFORMS.length} plataformas.`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
