import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/loading_indicator.dart';
import 'providers/categories_provider.dart';

class CategorySelectionScreen extends ConsumerWidget {
  const CategorySelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(allCategoriesProvider);
    final selected = ref.watch(selectedCategoryIdsProvider);

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
            children: [
              Text(
                'Elige una o varias. Filtraremos el catálogo para los dos.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Expanded(
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
              PrimaryButton(
                label: 'Continuar',
                onPressed: selected.isEmpty
                    ? null
                    : () async {
                        await ref.read(categoriesRepositoryProvider).setForCouple(selected.toList());
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
