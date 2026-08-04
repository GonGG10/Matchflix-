#!/bin/bash
# Script de configuración para MatchFlix
# Ejecuta esto en tu ordenador después de descomprimir el proyecto
#
# Requisitos:
#   - Flutter instalado (https://docs.flutter.dev/get-started/install)
#   - Para iOS: Mac con Xcode
#
# Uso:
#   chmod +x setup.sh
#   ./setup.sh

set -e

echo "🎬 MatchFlix — Script de configuración"
echo "========================================"

# Detectar OS
OS=$(uname)

# ── Backend ──
echo ""
echo "📦 Configurando el backend..."
cd backend

if [ ! -f .env ]; then
  cp .env.example .env
  echo "✅ Archivo .env creado. Edítalo con tu DATABASE_URL y WATCHMODE_API_KEY"
else
  echo "ℹ️  .env ya existe"
fi

echo "   Instalando dependencias del backend..."
npm install 2>/dev/null

echo "   Generando cliente Prisma..."
npx prisma generate 2>/dev/null

echo "   Compilando backend..."
npm run build 2>/dev/null

echo ""
echo "✅ Backend listo"
echo "   Para arrancarlo: cd backend && npm run start:dev"
echo "   (necesitas PostgreSQL corriendo y el .env configurado)"

cd ..

# ── Frontend ──
echo ""
echo "📱 Configurando el frontend..."
cd frontend

echo "   Instalando dependencias de Flutter..."
flutter pub get 2>/dev/null

# Generar archivos de plataforma si no existen
if [ "$OS" = "Darwin" ]; then
  # macOS — puede generar iOS y web
  if [ ! -d "ios" ] || [ ! -f "ios/Runner.xcodeproj/project.pbxproj" ]; then
    echo "   Generando proyecto Xcode para iOS..."
    flutter create . --platforms=ios --project-name=matchflix 2>/dev/null
  fi
  if [ ! -d "macos" ]; then
    flutter create . --platforms=macos --project-name=matchflix 2>/dev/null
  fi
fi

# Web siempre
if [ ! -d "web" ]; then
  flutter create . --platforms=web --project-name=matchflix 2>/dev/null
fi

echo ""
echo "✅ Frontend listo"
echo ""
echo "   Para ejecutar en web:      cd frontend && flutter run -d chrome"
echo "   Para ejecutar en iOS:      cd frontend && flutter run -d ios"
echo "   Para ejecutar en Android:  cd frontend && flutter run -d android"
echo ""
echo "⚠️  Recuerda cambiar la URL del backend en lib/core/network/api_endpoints.dart"
echo "   o pasarla con --dart-define=API_BASE_URL=https://tu-backend.onrender.com"
echo ""
echo "🎬 ¡Listo! Ya puedes ejecutar MatchFlix"
