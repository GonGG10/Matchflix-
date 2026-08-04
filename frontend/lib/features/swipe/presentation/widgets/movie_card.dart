import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/platform_chip.dart';
import '../../domain/movie_entity.dart';

class MovieCard extends StatelessWidget {
  const MovieCard({super.key, required this.movie});
  final MovieEntity movie;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (movie.posterUrl != null)
            CachedNetworkImage(
              imageUrl: movie.posterUrl!,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: AppColors.surface),
              errorWidget: (_, __, ___) => Container(color: AppColors.surface),
            )
          else
            Container(
              color: AppColors.surface,
              child: const Icon(Icons.movie_creation_outlined, size: 64, color: AppColors.textMuted),
            ),

          // Degradado para que el texto sea legible sobre el póster.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
                  stops: const [0.45, 1.0],
                ),
              ),
            ),
          ),

          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movie.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (movie.year != null) _MetaText('${movie.year}'),
                    if (movie.durationMinutes != null) _MetaText('${movie.durationMinutes} min'),
                    if (movie.imdbRating != null) _MetaText('★ ${movie.imdbRating!.toStringAsFixed(1)}'),
                  ],
                ),
                if (movie.genres.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    movie.genres.take(4).join(' · '),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
                if (movie.synopsis != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    movie.synopsis!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.35),
                  ),
                ],
                if (movie.platforms.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: movie.platforms
                        .map((p) => PlatformChip(name: p.name, logoUrl: p.logoUrl))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaText extends StatelessWidget {
  const _MetaText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }
}
