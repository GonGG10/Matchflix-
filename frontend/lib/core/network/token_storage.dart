import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Guarda el JWT de sesión.
///
/// En web usamos SharedPreferences (localStorage), que sobrevive a
/// recargas de forma consistente en todos los navegadores. flutter_secure_storage
/// en web depende de IndexedDB + WebCrypto, que en algunos navegadores
/// (Safari/iPad en modo privado, particiones de almacenamiento estrictas, etc.)
/// puede perder la clave de cifrado y, con ella, la sesión guardada — eso es
/// lo que provocaba que la app "no recordara" el login.
/// En móvil/escritorio seguimos usando el almacenamiento seguro nativo
/// (Keychain / Keystore), que es la opción correcta ahí.
class TokenStorage {
  TokenStorage(this._secureStorage);

  final FlutterSecureStorage _secureStorage;
  static const _key = 'auth_token';

  Future<void> save(String token) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, token);
      return;
    }
    await _secureStorage.write(key: _key, value: token);
  }

  Future<String?> read() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_key);
    }
    return _secureStorage.read(key: _key);
  }

  Future<void> clear() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
      return;
    }
    await _secureStorage.delete(key: _key);
  }
}
