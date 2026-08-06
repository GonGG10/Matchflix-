import 'package:dio/dio.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/movie_entity.dart';

class MoviesRepository {
  MoviesRepository(this._dio);
  final Dio _dio;

  /// fetchNext acepta [excludeIds] y [mediaType] para filtrar correctamente.
  Future<MovieEntity?> fetchNext({
    List<String>? excludeIds,
    String? mediaType,
  }) async {
    final params = <String, dynamic>{};
    if (excludeIds != null && excludeIds.isNotEmpty) {
      params['excludeIds'] = excludeIds.join(',');
    }
    if (mediaType != null) {
      params['mediaType'] = mediaType;
    }

    final response = await _dio.get(
      ApiEndpoints.nextMovie,
      queryParameters: params.isEmpty ? null : params,
    );
    if (response.data == null) return null;
    return MovieEntity.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> resetSwipes() async {
    await _dio.post(ApiEndpoints.resetSwipes);
  }

  Future<void> sendSwipe({required String movieId, required bool liked}) {
    return _dio.post(ApiEndpoints.swipes, data: {
      'movieId': movieId,
      'direction': liked ? 'LIKE' : 'DISLIKE',
    });
  }
}
