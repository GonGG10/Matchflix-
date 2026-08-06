import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/core_providers.dart';
import '../../../core/network/token_storage.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _decideRoute());
  }

  Future<void> _decideRoute() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final tokenStorage = ref.read(tokenStorageProvider);
    final token = await tokenStorage.read();

    if (token == null) {
      context.go('/');
      return;
    }

    // Verificar si la sala sigue activa
    try {
      final repo = ref.read(roomsRepositoryProvider);
      final status = await repo.getRoomStatus();
      if (!mounted) return;
      final s = status['status'] as String?;
      if (s == 'ACTIVE') {
        context.go('/swipe');
      } else if (s == 'PENDING') {
        context.go('/room/code', extra: {
          'inviteCode': status['inviteCode'] ?? '',
          'expiresAt': status['expiresAt'] ?? '',
        });
      } else {
        await tokenStorage.clear();
        context.go('/');
      }
    } catch (_) {
      await tokenStorage.clear();
      if (mounted) context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Logo(),
            SizedBox(height: 16),
            Text('MatchFlix', style: TextStyle(color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.w700)),
            SizedBox(height: 8),
            SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.like)),
          ],
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Image.asset('assets/images/logo.png', width: 96, height: 96, fit: BoxFit.cover),
    );
  }
}
