import '../../swipe/domain/movie_entity.dart';

class MatchEntity {
  const MatchEntity({required this.id, required this.status, required this.movie});
  final String id;
  final String status; // PENDING | WATCHED | REMOVED
  final MovieEntity movie;

  factory MatchEntity.fromJson(Map<String, dynamic> json) => MatchEntity(
        id: json['id'] as String,
        status: json['status'] as String,
        movie: MovieEntity.fromJson(json['movie'] as Map<String, dynamic>),
      );
}
