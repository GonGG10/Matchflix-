import 'package:dio/dio.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/match_entity.dart';

class MatchesRepository {
  MatchesRepository(this._dio);
  final Dio _dio;

  Future<List<MatchEntity>> findAll() async {
    final response = await _dio.get(ApiEndpoints.matches);
    return (response.data as List).map((e) => MatchEntity.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> markWatched(String matchId) => _dio.patch('${ApiEndpoints.matches}/$matchId/watched');

  Future<void> remove(String matchId) => _dio.delete('${ApiEndpoints.matches}/$matchId');
}
