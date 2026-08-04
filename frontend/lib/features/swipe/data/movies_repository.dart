import 'package:dio/dio.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/movie_entity.dart';

class MoviesRepository {
  MoviesRepository(this._dio);
  final Dio _dio;

  Future<MovieEntity?> fetchNext() async {
    final response = await _dio.get(ApiEndpoints.nextMovie);
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
