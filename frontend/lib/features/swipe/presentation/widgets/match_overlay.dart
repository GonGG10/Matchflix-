import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/movie_entity.dart';

/// Overlay que se muestra cuando ambos miembros de la pareja dan LIKE a la
/// misma película. Si [maxMatchesReached] es true, muestra un mensaje
/// especial indicando que ya tienen suficientes matches para elegir.
class MatchOverlay extends StatelessWidget {
  const MatchOverlay({
    super.key,
    required this.movie,
    required this.onClose,
    this.maxMatchesReached = false,
    this.matchCount = 0,
  });

  final MovieEntity movie;
  final VoidCallback onClose;
  final bool maxMatchesReached;
  final int matchCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Corazón animado
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.5, end: 1.0),
                duration: const Duration(milliseconds: 400),
                curve: Curves.elasticOut,
                builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: AppColors.like,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.favorite, color: Colors.white, size: 44),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '¡Match!',
                style: TextStyle(
                  color: AppColors.like,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'A los dos os gusta "${movie.title}"',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 18),
              ),
              const SizedBox(height: 24),
              if (maxMatchesReached) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.like.withOpacity(0.4)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.celebration_rounded, color: AppColors.like, size: 36),
                      const SizedBox(height: 12),
                      Text(
                        '¡Ya tenéis $matchCount películas que os encantan!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Es el momento de elegir qué ver esta noche.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.like,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      onClose();
                      context.go('/matches');
                    },
                    child: const Text('Ver nuestros matches', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: onClose,
                  child: const Text('Seguir deslizando', style: TextStyle(color: AppColors.textSecondary)),
                ),
              ] else ...[
                Text(
                  'Lleváis $matchCount ${matchCount == 1 ? "match" : "matches"}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: onClose,
                  child: const Text('Continuar', style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
