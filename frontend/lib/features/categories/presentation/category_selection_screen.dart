import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/loading_indicator.dart';
import 'providers/categories_provider.dart';
import '../../filters/presentation/providers/filters_provider.dart';

class CategorySelectionScreen extends ConsumerWidget {
  const CategorySelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(allCategoriesProvider);
    final selected = ref.watch(selectedCategoryIdsProvider);
    final mediaType = ref.watch(selectedMediaTypeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('¿Qué os apetece ver?')),
      body: categoriesAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => const Center(
          child: Text('No se pudieron cargar las categorías', style: TextStyle(color: AppColors.textSecondary)),
        ),
        data: (categories) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Selector de tipo: Películas / Series / Todo ---
              Text('Tipo de contenido', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                children: [
                  _MediaTypeChip(
                    label: 'Todo',
                    icon: Icons.movie_filter_outlined,
                    selected: mediaType == null,
                    onTap: () => ref.read(selectedMediaTypeProvider.notifier).state = null,
                  ),
                  _MediaTypeChip(
                    label: 'Películas',
                    icon: Icons.movie_outlined,
                    selected: mediaType == 'MOVIE',
                    onTap: () => ref.read(selectedMediaTypeProvider.notifier).state = 'MOVIE',
                  ),
                  _MediaTypeChip(
                    label: 'Series',
                    icon: Icons.tv_outlined,
                    selected: mediaType == 'SERIES',
                    onTap: () => ref.read(selectedMediaTypeProvider.notifier).state = 'SERIES',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // --- Categorías / géneros ---
              Text('Categorías', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Elige una o varias. Filtraremos el catálogo para los dos.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: categories.map((c) {
                      final isSelected = selected.contains(c.id);
                      return GestureDetector(
                        onTap: () {
                          final next = {...selected};
                          isSelected ? next.remove(c.id) : next.add(c.id);
                          ref.read(selectedCategoryIdsProvider.notifier).state = next;
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.like : AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? AppColors.like : AppColors.surfaceBorder,
                            ),
                          ),
                          child: Text(
                            c.name,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Continuar',
                onPressed: selected.isEmpty
                    ? null
                    : () async {
                        // Guardar categorías en el backend
                        await ref.read(categoriesRepositoryProvider).setForCouple(selected.toList());

                        // Guardar el mediaType como filtro de la pareja
                        final filtersRepo = ref.read(filtersRepositoryProvider);
                        try {
                          await filtersRepo.save({'mediaType': mediaType});
                        } catch (_) {}

                        if (context.mounted) context.go('/swipe');
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MediaTypeChip extends StatelessWidget {
  const _MediaTypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.like : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.like : AppColors.surfaceBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: selected ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
