import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import 'providers/couple_provider.dart';

class JoinCoupleScreen extends ConsumerStatefulWidget {
  const JoinCoupleScreen({super.key});

  @override
  ConsumerState<JoinCoupleScreen> createState() => _JoinCoupleScreenState();
}

class _JoinCoupleScreenState extends ConsumerState<JoinCoupleScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Si la pantalla se recarga y el usuario ya pertenece a una pareja,
    // lo mandamos directo en vez de dejarle intentar unirse otra vez.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkExisting());
  }

  Future<void> _checkExisting() async {
    try {
      final existing = await ref.read(coupleRepositoryProvider).myCouple();
      ref.read(authControllerProvider.notifier).setCoupleId(existing['id'] as String);
      if (!mounted) return;
      context.go(existing['status'] == 'ACTIVE' ? '/categories' : '/couple/create/code');
    } catch (_) {
      // No pertenece a ninguna pareja todavía: se queda en esta pantalla.
    }
  }

  Future<void> _join() async {
    setState(() { _loading = true; _error = null; });
    try {
      final couple = await ref.read(coupleRepositoryProvider).join(_controller.text.trim());
      ref.read(authControllerProvider.notifier).setCoupleId(couple['id'] as String);
      if (mounted) context.go('/categories');
    } catch (_) {
      setState(() => _error = 'Código no válido o la pareja ya está completa.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Unirme a una pareja')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _controller,
              textCapitalization: TextCapitalization.characters,
              textAlign: TextAlign.center,
              maxLength: 6,
              style: const TextStyle(fontSize: 24, letterSpacing: 4),
              decoration: const InputDecoration(labelText: 'Código de 6 caracteres'),
            ),
            if (_error != null) Text(_error!, style: const TextStyle(color: AppColors.like)),
            const SizedBox(height: 16),
            PrimaryButton(label: 'Unirme', isLoading: _loading, onPressed: _join),
          ],
        ),
      ),
    );
  }
}
