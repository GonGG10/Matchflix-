import 'package:flutter/foundation.dart' show kIsWeb;
import '../network/web_session_storage_stub.dart'
    if (dart.library.html) '../network/web_session_storage_impl.dart';

/// Almacena los IDs de películas/series ya vistas en sessionStorage.
/// Persiste entre recreaciones del SwipeController y recargas de página.
/// Se limpia cuando se crea una sala nueva.
class SeenMoviesStorage {
  final WebSessionStorage _storage = WebSessionStorage();
  static const _key = 'seen_movie_ids';

  Set<String> load() {
    final raw = _storage.getItem(_key);
    if (raw == null || raw.isEmpty) return {};
    return raw.split(',').where((id) => id.isNotEmpty).toSet();
  }

  void add(String movieId) {
    final current = load();
    if (current.contains(movieId)) return;
    current.add(movieId);
    _storage.setItem(_key, current.join(','));
  }

  void addAll(Iterable<String> ids) {
    final current = load();
    current.addAll(ids);
    _storage.setItem(_key, current.join(','));
  }

  void clear() {
    _storage.removeItem(_key);
  }

  bool contains(String movieId) {
    return load().contains(movieId);
  }
}
