// Variables globales anti-repetición que persisten durante toda la sesión.
// Separamos esto en un archivo independiente para evitar dependencias circulares.

/// IDs de películas ya vistas — persiste en memoria durante toda la sesión.
/// Sobrevive a recreaciones del SwipeController (autoDispose) y errores de red.
/// Se limpia cuando se crea/une a una sala nueva.
final Set<String> globalSwipedIds = {};

/// Limpia los IDs globales — llamar al crear/unirse a una sala nueva.
void clearGlobalSwipedIds() {
  globalSwipedIds.clear();
}
