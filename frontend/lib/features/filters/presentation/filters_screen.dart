import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/primary_button.dart';
import 'providers/filters_provider.dart';

class FiltersScreen extends ConsumerWidget {
  const FiltersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(filtersControllerProvider);
    final controller = ref.read(filtersControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Filtros')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Duración máxima', style: Theme.of(context).textTheme.titleLarge),
          Text(
            filters.maxDuration != null ? '${filters.maxDuration} min' : 'Sin límite',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          Slider(
            value: (filters.maxDuration ?? 240).toDouble(),
            min: 60,
            max: 240,
            divisions: 18,
            activeColor: AppColors.like,
            onChanged: (v) => controller.setMaxDuration(v.round()),
          ),
          const SizedBox(height: 16),
          Text('Valoración mínima (IMDb)', style: Theme.of(context).textTheme.titleLarge),
          Text(
            filters.minRating != null ? filters.minRating!.toStringAsFixed(1) : 'Cualquiera',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          Slider(
            value: filters.minRating ?? 0,
            min: 0,
            max: 10,
            divisions: 20,
            activeColor: AppColors.like,
            onChanged: (v) => controller.setMinRating(v),
          ),
          const SizedBox(height: 16),
          Text('Tipo', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: [
              _TypeChip(label: 'Todo', selected: filters.mediaType == null, onTap: () => controller.setMediaType(null)),
              _TypeChip(label: 'Películas', selected: filters.mediaType == 'MOVIE', onTap: () => controller.setMediaType('MOVIE')),
              _TypeChip(label: 'Series', selected: filters.mediaType == 'SERIES', onTap: () => controller.setMediaType('SERIES')),
            ],
          ),
          const SizedBox(height: 32),
          PrimaryButton(
            label: 'Guardar filtros',
            onPressed: () async {
              await controller.save();
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.like : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.like : AppColors.surfaceBorder),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : AppColors.textPrimary)),
      ),
    );
  }
}
