import 'package:dio/dio.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/movie_entity.dart';

class MoviesRepository {
  MoviesRepository(this._dio);
  final Dio _dio;

  /// fetchNext acepta [excludeIds] — IDs de películas que ya hemos visto
  /// en esta sesión, para que el backend no nos las devuelva otra vez.
  Future<MovieEntity?> fetchNext({List<String>? excludeIds}) async {
    final response = await _dio.get(
      ApiEndpoints.nextMovie,
      queryParameters: excludeIds != null && excludeIds.isNotEmpty
          ? {'excludeIds': excludeIds.join(',')}
          : null,
    );
    if (response.data == null) return null;
    return MovieEntity.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> sendSwipe({required String movieId, required bool liked}) {
    return _dio.post(ApiEndpoints.swipes, data: {
      'movieId': movieId,
      'direction': liked ? 'LIKE' : 'DISLIKE',
    });
  }
}
