import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_indicator.dart';
import 'providers/swipe_provider.dart';
import 'widgets/movie_card.dart';
import 'widgets/match_overlay.dart';

const _swipeThreshold = 110.0;

class SwipeScreen extends ConsumerStatefulWidget {
  const SwipeScreen({super.key});

  @override
  ConsumerState<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends ConsumerState<SwipeScreen> with SingleTickerProviderStateMixin {
  Offset _dragOffset = Offset.zero;
  bool _dragging = false;
  late final AnimationController _flingController;
  Animation<Offset>? _flingAnimation;
  bool? _pendingLiked;

  @override
  void initState() {
    super.initState();
    _flingController = AnimationController(vsync: this, duration: const Duration(milliseconds: 260))
      ..addListener(() {
        if (_flingAnimation != null) setState(() => _dragOffset = _flingAnimation!.value);
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && _pendingLiked != null) {
          final liked = _pendingLiked!;
          _pendingLiked = null;
          ref.read(swipeControllerProvider.notifier).swipe(liked: liked);
          setState(() => _dragOffset = Offset.zero);
        }
      });
  }

  @override
  void dispose() {
    _flingController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragging = true;
      _dragOffset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _dragging = false;
    if (_dragOffset.dx.abs() > _swipeThreshold) {
      _completeSwipe(liked: _dragOffset.dx > 0);
    } else {
      _snapBack();
    }
  }

  void _snapBack() {
    _flingAnimation = Tween<Offset>(begin: _dragOffset, end: Offset.zero)
        .animate(CurvedAnimation(parent: _flingController, curve: Curves.easeOutBack));
    _pendingLiked = null;
    _flingController.forward(from: 0);
  }

  void _completeSwipe({required bool liked}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final target = Offset(liked ? screenWidth * 1.4 : -screenWidth * 1.4, _dragOffset.dy);
    _flingAnimation = Tween<Offset>(begin: _dragOffset, end: target)
        .animate(CurvedAnimation(parent: _flingController, curve: Curves.easeIn));
    _pendingLiked = liked;
    _flingController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(swipeControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Descubrir'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => context.push('/filters'),
          ),
          IconButton(
            icon: const Icon(Icons.favorite_rounded, color: AppColors.like),
            onPressed: () => context.push('/matches'),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_rounded),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (state.isLoading)
            const LoadingIndicator(message: 'Buscando películas para vosotros…')
          else if (state.errorMessage != null)
            _ErrorState(
              message: state.errorMessage!,
              onRetry: () => ref.read(swipeControllerProvider.notifier).retry(),
            )
          else if (state.noMoreMovies || state.currentMovie == null)
            _EmptyState(onAdjustFilters: () => context.push('/filters'))
          else
            _buildCardStack(state),

          if (state.matchedMovie != null)
            MatchOverlay(
              movie: state.matchedMovie!,
              onClose: () => ref.read(swipeControllerProvider.notifier).dismissMatch(),
            ),
        ],
      ),
    );
  }

  Widget _buildCardStack(SwipeState state) {
    final rotation = (_dragOffset.dx / 300).clamp(-0.4, 0.4);
    final likeOpacity = (_dragOffset.dx / _swipeThreshold).clamp(0.0, 1.0);
    final nopeOpacity = (-_dragOffset.dx / _swipeThreshold).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (state.nextMovie != null)
                  Transform.scale(scale: 0.94, child: MovieCard(movie: state.nextMovie!)),
                GestureDetector(
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  child: Transform.translate(
                    offset: _dragOffset,
                    child: Transform.rotate(
                      angle: rotation,
                      child: Stack(
                        children: [
                          MovieCard(movie: state.currentMovie!),
                          Positioned(
                            top: 32,
                            left: 24,
                            child: Opacity(opacity: nopeOpacity, child: const _StampLabel('NO', color: AppColors.dislike)),
                          ),
                          Positioned(
                            top: 32,
                            right: 24,
                            child: Opacity(opacity: likeOpacity, child: const _StampLabel('ME GUSTA', color: AppColors.like)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _RoundActionButton(
                icon: Icons.close_rounded,
                color: AppColors.dislike,
                onTap: () => _completeSwipe(liked: false),
              ),
              const SizedBox(width: 28),
              _RoundActionButton(
                icon: Icons.favorite_rounded,
                color: AppColors.like,
                large: true,
                onTap: () => _completeSwipe(liked: true),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StampLabel extends StatelessWidget {
  const _StampLabel(this.text, {required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.2,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 3),
          borderRadius: BorderRadius.circular(10),
          color: Colors.black.withOpacity(0.3),
        ),
        child: Text(
          text,
          style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: 1),
        ),
      ),
    );
  }
}

class _RoundActionButton extends StatelessWidget {
  const _RoundActionButton({required this.icon, required this.color, required this.onTap, this.large = false});
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final size = large ? 64.0 : 54.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surface,
          border: Border.all(color: color.withOpacity(0.5), width: 1.5),
          boxShadow: [BoxShadow(color: color.withOpacity(0.25), blurRadius: 16, spreadRadius: 1)],
        ),
        child: Icon(icon, color: color, size: large ? 30 : 26),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 56, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 20),
            OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdjustFilters});
  final VoidCallback onAdjustFilters;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.movie_filter_outlined, size: 56, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text('Por ahora no hay más películas', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text(
              'Prueba a ampliar vuestras categorías o filtros.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            OutlinedButton(onPressed: onAdjustFilters, child: const Text('Ajustar filtros')),
          ],
        ),
      ),
    );
  }
}
