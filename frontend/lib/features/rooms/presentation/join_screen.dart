import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/core_providers.dart';

class JoinScreen extends ConsumerStatefulWidget {
  const JoinScreen({super.key});
  @override
  ConsumerState<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends ConsumerState<JoinScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _join() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length < 6) {
      setState(() => _error = 'Introduce el código de 6 caracteres');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      final repo = ref.read(roomsRepositoryProvider);
      final data = await repo.joinRoom(code);
      if (mounted) {
        context.go('/categories');
      }
    } catch (e) {
      setState(() {
        _error = 'No se pudo unir a la sala. Verifica el código e inténtalo de nuevo.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset('assets/images/logo.png', width: 64, height: 64, fit: BoxFit.cover),
                ),
                const SizedBox(height: 20),
                const Text('Introduce el código', textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                const Text('Pídele a tu pareja su código de sala', textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                const SizedBox(height: 32),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.surfaceBorder, width: 1.5),
                  ),
                  child: TextField(
                    controller: _codeController,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: 6),
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      hintText: 'ABC123',
                      hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 28, letterSpacing: 6),
                      counterText: '',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 18),
                    ),
                    onSubmitted: (_) => _join(),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.like, fontSize: 14)),
                ],
                const SizedBox(height: 28),
                GestureDetector(
                  onTap: _isLoading ? null : _join,
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFFF5D73), Color(0xFFFF8A5C)]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: _isLoading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Text('Unirse a la sala', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Volver', style: TextStyle(color: AppColors.textMuted)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
