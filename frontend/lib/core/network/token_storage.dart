import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'web_session_storage_stub.dart'
    if (dart.library.html) 'web_session_storage_impl.dart';

/// Guarda el JWT de sesión.
///
/// En web usamos sessionStorage (del navegador), que es POR PESTAÑA.
/// Esto permite tener dos pestañas abiertas con usuarios distintos sin
/// que se pisen el token. Sobrevive a recargas dentro de la misma pestaña.
/// En móvil/escritorio seguimos usando el almacenamiento seguro nativo.
class TokenStorage {
  TokenStorage(this._secureStorage);

  final FlutterSecureStorage _secureStorage;
  final WebSessionStorage _webStorage = WebSessionStorage();
  static const _key = 'auth_token';

  Future<void> save(String token) async {
    if (kIsWeb) {
      _webStorage.setItem(_key, token);
      return;
    }
    await _secureStorage.write(key: _key, value: token);
  }

  Future<String?> read() async {
    if (kIsWeb) {
      return _webStorage.getItem(_key);
    }
    return _secureStorage.read(key: _key);
  }

  Future<void> clear() async {
    if (kIsWeb) {
      _webStorage.removeItem(_key);
      return;
    }
    await _secureStorage.delete(key: _key);
  }
}
