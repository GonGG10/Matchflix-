import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Perfil')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.surfaceElevated,
              child: Text(
                (user?.displayName.isNotEmpty == true ? user!.displayName[0] : '?').toUpperCase(),
                style: const TextStyle(fontSize: 28, color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: 16),
            Text(user?.displayName ?? '', style: Theme.of(context).textTheme.headlineMedium),
            Text(user?.email ?? '', style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 32),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.tune_rounded, color: AppColors.textSecondary),
              title: const Text('Filtros'),
              onTap: () => context.push('/filters'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.category_outlined, color: AppColors.textSecondary),
              title: const Text('Categorías'),
              onTap: () => context.push('/categories'),
            ),
            const Spacer(),
            OutlinedButton(
              onPressed: () async {
                await ref.read(authControllerProvider.notifier).logout();
                if (context.mounted) context.go('/welcome');
              },
              child: const Text('Cerrar sesión'),
            ),
          ],
        ),
      ),
    );
  }
}
