import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

/// Configuración de endpoints de la API.
///
/// Cambia [kApiBaseUrl] y [kSocketBaseUrl] por la URL de tu servidor en Render
/// antes de compilar la versión de producción.
///
/// Para desarrollo local:
///   - Emulador Android: http://10.0.2.2:3000
///   - iOS Simulator:     http://localhost:3000
///   - Dispositivo físico: http://<IP-de-tu-Mac>:3000
class ApiEndpoints {
  ApiEndpoints._();

  // ──────────────────────────────────────────────────────────────
  //  CONFIGURACIÓN — Cambia esto por tu URL de Render en producción
  // ──────────────────────────────────────────────────────────────
  //
  // Ejemplo de producción:
  //   static const String kApiBaseUrl = 'https://matchflix-backend.onrender.com';
  //   static const String kSocketBaseUrl = 'wss://matchflix-backend.onrender.com';
  //
  // Para desarrollo (iOS Simulator):
  //   static const String kApiBaseUrl = 'http://localhost:3000';
  //   static const String kSocketBaseUrl = 'http://localhost:3000';

  static const String kApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000', // iOS Simulator por defecto
  );

  static const String kSocketBaseUrl = String.fromEnvironment(
    'SOCKET_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  // ──────────────────────────────────────────────────────────────
  //  Endpoints derivados — no tocar
  // ──────────────────────────────────────────────────────────────

  static String get baseUrl => '$kApiBaseUrl/api';
  static String get socketUrl => kSocketBaseUrl;

  static const register = '/auth/register';
  static const login = '/auth/login';
  static const me = '/users/me';
  static const couples = '/couples';
  static const joinCouple = '/couples/join';
  static const myCouple = '/couples/me';
  static const categories = '/categories';
  static const coupleCategories = '/categories/couple';
  static const platforms = '/platforms';
  static const nextMovie = '/movies/next';
  static const swipes = '/swipes';
  static const matches = '/matches';
}
