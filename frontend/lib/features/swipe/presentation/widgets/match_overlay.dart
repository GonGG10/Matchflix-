import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/movie_entity.dart';

/// Animación de "¡Habéis hecho Match!" que aparece en ambos móviles a la vez
/// (llega vía WebSocket, ver SwipeController._connectRealtime).
class MatchOverlay extends StatelessWidget {
  const MatchOverlay({super.key, required this.movie, required this.onClose});
  final MovieEntity movie;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.88),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.6, end: 1.0),
          duration: const Duration(milliseconds: 450),
          curve: Curves.elasticOut,
          builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => AppColors.gradientMatch.createShader(bounds),
                child: const Text(
                  '¡Habéis hecho\nMatch!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white, height: 1.15),
                ),
              ),
              const SizedBox(height: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  width: 180,
                  height: 260,
                  child: movie.posterUrl != null
                      ? Image.network(movie.posterUrl!, fit: BoxFit.cover)
                      : Container(color: AppColors.surface),
                ),
              ),
              const SizedBox(height: 16),
              Text(movie.title, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: () {
                  onClose();
                  context.push('/matches');
                },
                child: const Text('Ver en Matches'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: onClose,
                child: const Text('Seguir deslizando', style: TextStyle(color: AppColors.textSecondary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
