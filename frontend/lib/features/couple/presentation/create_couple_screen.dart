import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import 'providers/couple_provider.dart';

/// Pantalla intermedia: crear pareja nueva o unirse con un código.
class CoupleWelcomeScreen extends ConsumerWidget {
  const CoupleWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Vuestra pareja')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Para empezar a hacer match necesitáis estar unidos como pareja dentro de la app.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            PrimaryButton(label: 'Crear pareja', onPressed: () => context.push('/couple/create/code')),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Unirme con un código',
              filled: false,
              onPressed: () => context.push('/couple/join'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Muestra el código de invitación generado para que la pareja lo introduzca.
class CoupleCodeScreen extends ConsumerStatefulWidget {
  const CoupleCodeScreen({super.key});

  @override
  ConsumerState<CoupleCodeScreen> createState() => _CoupleCodeScreenState();
}

class _CoupleCodeScreenState extends ConsumerState<CoupleCodeScreen> {
  String? _code;
  String? _error;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _createCouple();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _createCouple() async {
    // Si la pantalla se recarga (p.ej. Safari suspende la pestaña) y el usuario
    // ya pertenece a una pareja, reutilizamos esa pareja en vez de intentar
    // crear una nueva (lo que provocaría un error de conflicto).
    try {
      final existing = await ref.read(coupleRepositoryProvider).myCouple();
      ref.read(authControllerProvider.notifier).setCoupleId(existing['id'] as String);
      if (existing['status'] == 'ACTIVE') {
        if (mounted) context.go('/categories');
        return;
      }
      if (!mounted) return;
      setState(() => _code = existing['inviteCode'] as String);
      _startPolling();
      return;
    } catch (_) {
      // El usuario todavía no tiene pareja: seguimos para crear una nueva.
    }

    try {
      final couple = await ref.read(coupleRepositoryProvider).create();
      if (!mounted) return;
      setState(() => _code = couple['inviteCode'] as String);
      ref.read(authControllerProvider.notifier).setCoupleId(couple['id'] as String);
      _startPolling();
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo crear la pareja. Inténtalo de nuevo.');
    }
  }

  // Sondea cada 3s hasta que la pareja tenga 2 miembros (status ACTIVE),
  // momento en el que ambos avanzan automáticamente a elegir categorías.
  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        final couple = await ref.read(coupleRepositoryProvider).myCouple();
        if (couple['status'] == 'ACTIVE' && mounted) {
          _pollTimer?.cancel();
          context.go('/categories');
        }
      } catch (_) {
        // se reintenta en el siguiente tick
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Código de invitación')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_error != null) Text(_error!, style: const TextStyle(color: AppColors.like)),
            if (_code == null && _error == null) const CircularProgressIndicator(color: AppColors.like),
            if (_code != null) ...[
              const Text('Compartid este código', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Center(
                  child: Text(
                    _code!,
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 6, color: AppColors.textPrimary),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'En cuanto tu pareja lo introduzca, continuad juntos con la selección de categorías.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
