import 'package:dio/dio.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/token_storage.dart';

class RoomsRepository {
  RoomsRepository(this._dio, this._tokenStorage);
  final Dio _dio;
  final TokenStorage _tokenStorage;

  Future<Map<String, dynamic>> createRoom() async {
    final response = await _dio.post('${ApiEndpoints.baseUrl}/rooms/create');
    final data = response.data as Map<String, dynamic>;
    await _tokenStorage.save(data['accessToken'] as String);
    return data;
  }

  Future<Map<String, dynamic>> joinRoom(String inviteCode) async {
    final response = await _dio.post(
      '${ApiEndpoints.baseUrl}/rooms/join',
      data: {'inviteCode': inviteCode},
    );
    final data = response.data as Map<String, dynamic>;
    await _tokenStorage.save(data['accessToken'] as String);
    return data;
  }

  Future<Map<String, dynamic>> getRoomStatus() async {
    final response = await _dio.get('${ApiEndpoints.baseUrl}/rooms/status');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> syncCatalog({bool force = false}) async {
    final url = force
        ? '${ApiEndpoints.baseUrl}/catalog/sync?force=true'
        : '${ApiEndpoints.baseUrl}/catalog/sync';
    final response = await _dio.post(url);
    return response.data as Map<String, dynamic>;
  }
}
