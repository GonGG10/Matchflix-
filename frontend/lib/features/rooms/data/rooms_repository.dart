import 'dart:math';
import 'package:dio/dio.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/token_storage.dart';
import '../../../core/storage/seen_movies_storage.dart';

/// Repositorio de salas temporales.
///
/// Usa los endpoints /auth/register + /couples que ya están desplegados
/// y funcionando en el backend. Crea usuarios anónimos automáticamente.
class RoomsRepository {
  RoomsRepository(this._dio, this._tokenStorage);
  final Dio _dio;
  final TokenStorage _tokenStorage;

  static const _roomTtlMinutes = 15;

  String _randomId() {
    final r = Random();
    return '${DateTime.now().millisecondsSinceEpoch}${r.nextInt(999999)}${r.nextInt(999)}';
  }

  String _randomName() {
    const names = ['Cinéfilo', 'Director', 'Crítico', 'Estrella', 'Artista', 'Guionista', 'Productor', 'Fanático'];
    return '${names[Random().nextInt(names.length)]}-${Random().nextInt(900) + 100}';
  }

  /// Crea una sala: registra usuario anónimo + crea pareja PENDING.
  Future<Map<String, dynamic>> createRoom() async {
    // Limpiar películas vistas de sesiones anteriores
    SeenMoviesStorage().clear();

    final email = 'anon_${_randomId()}@matchflix.app';
    final password = 'Tx${_randomId()}#1a';
    final displayName = _randomName();

    final regRes = await _dio.post('${ApiEndpoints.baseUrl}/auth/register', data: {
      'email': email,
      'password': password,
      'displayName': displayName,
    });
    final token = (regRes.data as Map<String, dynamic>)['accessToken'] as String;
    await _tokenStorage.save(token);

    final coupleRes = await _dio.post('${ApiEndpoints.baseUrl}/couples');
    final couple = coupleRes.data as Map<String, dynamic>;

    final createdAt = DateTime.parse(couple['createdAt'] as String);
    final expiresAt = createdAt.add(const Duration(minutes: _roomTtlMinutes));

    return {
      'accessToken': token,
      'inviteCode': couple['inviteCode'],
      'coupleId': couple['id'],
      'displayName': displayName,
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  /// Se une a una sala existente con un código de invitación.
  Future<Map<String, dynamic>> joinRoom(String inviteCode) async {
    // Limpiar películas vistas de sesiones anteriores
    SeenMoviesStorage().clear();

    final email = 'anon_${_randomId()}@matchflix.app';
    final password = 'Tx${_randomId()}#1a';
    final displayName = _randomName();

    final regRes = await _dio.post('${ApiEndpoints.baseUrl}/auth/register', data: {
      'email': email,
      'password': password,
      'displayName': displayName,
    });
    final token = (regRes.data as Map<String, dynamic>)['accessToken'] as String;
    await _tokenStorage.save(token);

    final joinRes = await _dio.post('${ApiEndpoints.baseUrl}/couples/join', data: {
      'inviteCode': inviteCode,
    });
    final couple = joinRes.data as Map<String, dynamic>;

    final createdAt = DateTime.parse(couple['createdAt'] as String);
    final expiresAt = createdAt.add(const Duration(minutes: _roomTtlMinutes));

    return {
      'accessToken': token,
      'inviteCode': couple['inviteCode'],
      'coupleId': couple['id'],
      'displayName': displayName,
      'expiresAt': expiresAt.toIso8601String(),
      'coupleStatus': couple['status'],
    };
  }

  /// Verifica el estado de la sala.
  Future<Map<String, dynamic>> getRoomStatus() async {
    try {
      final res = await _dio.get('${ApiEndpoints.baseUrl}/couples/me');
      final couple = res.data as Map<String, dynamic>;

      final createdAt = DateTime.parse(couple['createdAt'] as String);
      final expiresAt = createdAt.add(const Duration(minutes: _roomTtlMinutes));
      final now = DateTime.now();

      if (now.isAfter(expiresAt)) {
        return {
          'hasRoom': true,
          'status': 'EXPIRED',
          'coupleId': couple['id'],
          'inviteCode': couple['inviteCode'],
          'members': couple['members'],
          'expiresAt': expiresAt.toIso8601String(),
          'remainingMs': 0,
          'remainingMinutes': 0,
          'remainingSeconds': 0,
        };
      }

      final remainingMs = expiresAt.difference(now).inMilliseconds;
      return {
        'hasRoom': true,
        'status': couple['status'],
        'coupleId': couple['id'],
        'inviteCode': couple['inviteCode'],
        'members': couple['members'],
        'expiresAt': expiresAt.toIso8601String(),
        'remainingMs': remainingMs,
        'remainingMinutes': (remainingMs / 60000).floor(),
        'remainingSeconds': ((remainingMs % 60000) / 1000).floor(),
      };
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return {'hasRoom': false, 'status': 'NONE'};
      }
      rethrow;
    }
  }

  /// Sincroniza el catálogo de películas.
  Future<Map<String, dynamic>> syncCatalog({bool force = false}) async {
    final url = force
        ? '${ApiEndpoints.baseUrl}/catalog/sync?force=true'
        : '${ApiEndpoints.baseUrl}/catalog/sync';
    final res = await _dio.post(url);
    return res.data as Map<String, dynamic>;
  }
}
