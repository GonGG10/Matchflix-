class PlatformAvailability {
  const PlatformAvailability({required this.name, this.logoUrl});
  final String name;
  final String? logoUrl;

  factory PlatformAvailability.fromJson(Map<String, dynamic> json) {
    final platform = json['platform'] as Map<String, dynamic>;
    return PlatformAvailability(
      name: platform['name'] as String,
      logoUrl: platform['logoUrl'] as String?,
    );
  }
}

class MovieEntity {
  const MovieEntity({
    required this.id,
    required this.title,
    this.synopsis,
    this.posterUrl,
    this.year,
    this.durationMinutes,
    this.imdbRating,
    this.tmdbRating,
    required this.genres,
    required this.platforms,
  });

  final String id;
  final String title;
  final String? synopsis;
  final String? posterUrl;
  final int? year;
  final int? durationMinutes;
  final double? imdbRating;
  final double? tmdbRating;
  final List<String> genres;
  final List<PlatformAvailability> platforms;

  factory MovieEntity.fromJson(Map<String, dynamic> json) {
    return MovieEntity(
      id: json['id'] as String,
      title: json['title'] as String,
      synopsis: json['synopsis'] as String?,
      posterUrl: json['posterUrl'] as String?,
      year: json['year'] as int?,
      durationMinutes: json['durationMinutes'] as int?,
      imdbRating: (json['imdbRating'] as num?)?.toDouble(),
      tmdbRating: (json['tmdbRating'] as num?)?.toDouble(),
      genres: ((json['categories'] as List?) ?? [])
          .map((c) => (c['category']['name']) as String)
          .toList(),
      platforms: ((json['availability'] as List?) ?? [])
          .map((a) => PlatformAvailability.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }
}
