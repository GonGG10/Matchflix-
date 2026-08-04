# MatchFlix — Tinder de películas para parejas

App tipo Tinder para elegir películas: desliza a la derecha si te gusta, a la izquierda si no.
Cuando los dos miembros de la pareja dan like a la misma película → ¡Match!

El catálogo de películas se actualiza automáticamente cada día a las 3:00 AM desde la API de Watchmode.

## Arquitectura

```
App Flutter (Web / iOS)
      │
      ▼
Servidor NestJS (Render)
      │
      ▼
Watchmode API (actualización diaria 03:00)
```

---

## GUÍA PASO A PASO (no necesitas saber programar)

### Fase 1 — Crear cuentas (10 min)

1. **GitHub**: Si no tienes cuenta, créala en github.com (puedes registrarte con Google)

2. **Render**: Regístrate en render.com con tu cuenta de GitHub

3. **Neon (base de datos)**:
   - Entra en neon.tech → "Sign Up" → "Continue with Google"
   - Crea un proyecto llamado "matchflix"
   - Región: AWS Frankfurt (más cercana a España)
   - **Copia el connection string** (empieza con `postgresql://...`) — lo necesitarás

4. **Watchmode API**:
   - Regístrate en watchmode.com
   - Copia tu API key del panel

### Fase 2 — Subir el código a GitHub (5 min)

1. Descarga el archivo ZIP de MatchFlix y descomprímelo en tu ordenador
2. Entra en github.com → "New repository" → llámalo "matchflix" → Create
3. En la terminal de tu ordenador (o usando la GitHub CLI):
```bash
cd matchflix   # la carpeta que descomprimiste
git init
git add .
git commit -m "MatchFlix inicial"
git branch -M main
git remote add origin https://github.com/TU_USUARIO/matchflix.git
git push -u origin main
```

> ¿No tienes git instalado? Descárgalo de git-scm.com
> Alternativa sin terminal: arrastra los archivos a la web de GitHub

### Fase 3 — Desplegar el backend en Render (10 min)

1. Entra en render.com → "New" → "Blueprint"
2. Selecciona tu repositorio "matchflix" de GitHub
3. Render detecta el archivo `render.yaml` y configura todo automáticamente:
   - Crea la base de datos PostgreSQL
   - Crea el servidor NestJS
   - Configura todas las variables de entorno
4. Cuando te pida el valor de `WATCHMODE_API_KEY`, pega tu API key de Watchmode
5. Espera a que termine el despliegue (puede tardar 5-10 minutos)
6. **Anota la URL de tu backend** — algo como `https://matchflix-backend.onrender.com`

### Fase 4 — Probar que el backend funciona (2 min)

Abre en el navegador:
```
https://matchflix-backend.onrender.com/api
```
Debería responder con `{"statusCode":404,...}` o similar — significa que está funcionando.

Para forzar la primera sincronización del catálogo de películas, necesitarás
registrarte primero y luego hacer un POST a `/api/catalog/sync` con tu token JWT.
Ver la sección "Sincronización manual" más abajo.

### Fase 5 — Lanzar la versión Web (automático)

Si configuraste el workflow de GitHub Actions (`.github/workflows/deploy-web.yml`):

1. Ve a tu repositorio en GitHub → pestaña "Settings" → "Pages"
2. En "Source" selecciona "GitHub Actions"
3. Cada vez que hagas push a `main`, la web se compila y publica automáticamente
4. La URL será algo como: `https://TU_USUARIO.github.io/matchflix/`

**IMPORTANTE**: Antes del primer deploy, edita el archivo
`.github/workflows/deploy-web.yml` y cambia la URL
`https://matchflix-backend.onrender.com` por la URL real de tu backend en Render.

### Fase 6 (opcional) — App nativa para iPhone/iPad

Sin Mac no puedes compilar la app nativa directamente. Opciones:

**Opción A — Codemagic (recomendado)**:
1. Regístrate en codemagic.io (gratis)
2. Conecta tu repositorio de GitHub
3. Configura el build para iOS
4. Necesitas cuenta de Apple Developer ($99/año) para instalar vía TestFlight

**Opción B — Alquilar Mac en la nube**:
1. MacInCloud (~$20/mes) o similar
2. Instalar Flutter + Xcode
3. Compilar con cuenta gratuita de Apple (instalación de 7 días)

---

## Sincronización manual del catálogo

La primera vez, el catálogo está vacío. Tendrá que sincronizar a las 3:00 AM,
o puedes forzarla manualmente:

1. Regístrate en la app (versión web)
2. Usa el token que recibes al registrarte para hacer esta petición:

```bash
curl -X POST https://matchflix-backend.onrender.com/api/catalog/sync \
  -H "Authorization: Bearer TU_TOKEN_JWT"
```

Esto descarga el catálogo de Watchmode y lo guarda en la base de datos.
Puede tardar varios minutos dependiendo del tamaño del catálogo.

---

## Estructura del proyecto

```
matchflix/
├── render.yaml              # Blueprint para desplegar en Render
├── docker-compose.yml       # Para desarrollo local con Docker
├── .github/workflows/       # CI/CD — deploy web automático
├── backend/                 # Servidor NestJS + Prisma
│   ├── Dockerfile
│   ├── prisma/schema.prisma # Modelo de base de datos
│   └── src/
│       ├── auth/            # Login/registro con JWT
│       ├── couples/         # Parejas con código de invitación
│       ├── movies/          # Listado y siguiente película
│       ├── swipes/         # Lógica de LIKE/DISLIKE + detección de match
│       ├── matches/         # Gestión de matches
│       ├── catalog/        # Sincronización diaria con Watchmode
│       ├── filters/         # Filtros de pareja
│       └── realtime/        # WebSocket para notificación de match
└── frontend/               # App Flutter
    └── lib/
        ├── core/            # Tema, router, red, websockets
        ├── features/
        │   ├── splash, auth, couple, categories,
        │   │   swipe (pantalla tipo Tinder), matches, filters, profile
        └── shared/widgets/
```

## Variables de entorno del backend

| Variable | Descripción | Ejemplo |
|---|---|---|
| `DATABASE_URL` | URL de PostgreSQL (Neon) | `postgresql://...` |
| `JWT_SECRET` | Secreto para tokens | (auto-generado por Render) |
| `WATCHMODE_API_KEY` | Tu API key de Watchmode | `abc123...` |
| `WATCHMODE_BASE_URL` | URL de la API | `https://api.watchmode.com/v1` |
| `CATALOG_SYNC_COUNTRY` | País del catálogo | `ES` |
| `CATALOG_SYNC_CRON` | Horario de actualización | `0 3 * * *` |
| `CORS_ORIGIN` | Orígenes permitidos | `*` |

## Para desarrolladores

### Backend local
```bash
cd backend
cp .env.example .env
npm install
npx prisma migrate dev --name init
npm run prisma:seed
npm run start:dev
```

### Frontend local
```bash
cd frontend
flutter pub get
flutter run                    # móvil
flutter run -d chrome          # web
flutter build web --release    # build web de producción
```

### Cambiar la URL del backend en la app

Edita `frontend/lib/core/network/api_endpoints.dart`:
```dart
static const String kApiBaseUrl = 'https://matchflix-backend.onrender.com';
static const String kSocketBaseUrl = 'https://matchflix-backend.onrender.com';
```

O pásalo como dart-define:
```bash
flutter run --dart-define=API_BASE_URL=https://matchflix-backend.onrender.com
```
