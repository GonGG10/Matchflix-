import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_indicator.dart';
import 'providers/matches_provider.dart';

class MatchesScreen extends ConsumerWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(matchesListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Vuestros matches')),
      body: matchesAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => const Center(
          child: Text('No se pudieron cargar los matches', style: TextStyle(color: AppColors.textSecondary)),
        ),
        data: (matches) {
          if (matches.isEmpty) {
            return const Center(
              child: Text(
                'Todavía no tenéis ningún match.\n¡Seguid deslizando!',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(matchesListProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: matches.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final match = matches[index];
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 64,
                          height: 92,
                          child: match.movie.posterUrl != null
                              ? CachedNetworkImage(imageUrl: match.movie.posterUrl!, fit: BoxFit.cover)
                              : Container(color: AppColors.surfaceElevated),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(match.movie.title, style: Theme.of(context).textTheme.titleLarge, maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              children: match.movie.platforms
                                  .take(3)
                                  .map((p) => Text(p.name, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)))
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        color: AppColors.surfaceElevated,
                        icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                        onSelected: (value) async {
                          final repo = ref.read(matchesRepositoryProvider);
                          if (value == 'watched') await repo.markWatched(match.id);
                          if (value == 'remove') await repo.remove(match.id);
                          ref.invalidate(matchesListProvider);
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'watched', child: Text('Marcar como vista')),
                          PopupMenuItem(value: 'remove', child: Text('Eliminar')),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
