import 'dart:html';

/// Implementación web usando sessionStorage del navegador.
/// sessionStorage es POR PESTAÑA: dos pestañas del mismo navegador
/// NO comparten el token. Sobrevive a recargas dentro de la misma pestaña.
class WebSessionStorage {
  String? getItem(String key) => window.sessionStorage[key];
  void setItem(String key, String value) => window.sessionStorage[key] = value;
  void removeItem(String key) => window.sessionStorage.remove(key);
}
