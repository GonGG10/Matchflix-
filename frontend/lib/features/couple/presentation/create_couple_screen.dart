import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import 'providers/couple_provider.dart';

/// Pantalla combinada: muestra tu código de invitación para compartir,
/// Y permite meter el código de tu pareja para unirse.
/// Ambas opciones están visibles a la vez en la misma pantalla.
class CoupleCodeScreen extends ConsumerStatefulWidget {
  const CoupleCodeScreen({super.key});

  @override
  ConsumerState<CoupleCodeScreen> createState() => _CoupleCodeScreenState();
}

class _CoupleCodeScreenState extends ConsumerState<CoupleCodeScreen> {
  final _joinController = TextEditingController();
  bool _loading = false;
  bool _joining = false;
  String? _code;
  String? _error;
  String? _joinError;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _initCouple();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _joinController.dispose();
    super.dispose();
  }

  Future<void> _initCouple() async {
    // Si ya tiene pareja, reutilizarla
    try {
      final existing = await ref.read(coupleRepositoryProvider).myCouple();
      ref.read(authControllerProvider.notifier).setCoupleId(existing['id'] as String);
      if (existing['status'] == 'ACTIVE') {
        if (mounted) context.go('/categories');
        return;
      }
      if (!mounted) return;
      setState(() {
        _code = existing['inviteCode'] as String;
        _loading = false;
      });
      _startPolling();
      return;
    } catch (_) {
      // No tiene pareja: crear una nueva
    }

    setState(() => _loading = true);
    try {
      final couple = await ref.read(coupleRepositoryProvider).create();
      if (!mounted) return;
      setState(() {
        _code = couple['inviteCode'] as String;
        _loading = false;
      });
      ref.read(authControllerProvider.notifier).setCoupleId(couple['id'] as String);
      _startPolling();
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'No se pudo crear la pareja. Inténtalo de nuevo.';
          _loading = false;
        });
      }
    }
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        final couple = await ref.read(coupleRepositoryProvider).myCouple();
        if (couple['status'] == 'ACTIVE' && mounted) {
          _pollTimer?.cancel();
          context.go('/categories');
        }
      } catch (_) {}
    });
  }

  Future<void> _joinWithCode() async {
    final code = _joinController.text.trim().toUpperCase();
    if (code.length < 6) {
      setState(() => _joinError = 'El código tiene 6 caracteres.');
      return;
    }
    setState(() { _joining = true; _joinError = null; });
    try {
      final couple = await ref.read(coupleRepositoryProvider).join(code);
      ref.read(authControllerProvider.notifier).setCoupleId(couple['id'] as String);
      if (mounted) context.go('/categories');
    } catch (_) {
      setState(() => _joinError = 'Código no válido o la pareja ya está completa.');
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  void _copyCode() {
    if (_code == null) return;
    Clipboard.setData(ClipboardData(text: _code!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Código copiado'), duration: Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Conectar con tu pareja')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.like))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- SECCIÓN 1: Tu código ---
                    if (_error != null) ...[
                      Text(_error!, style: const TextStyle(color: AppColors.like), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                    ],
                    if (_code != null) ...[
                      // Tu código
                      const Text(
                        'Tu código de invitación',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _copyCode,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.surfaceBorder),
                          ),
                          child: Column(
                            children: [
                              Text(
                                _code!,
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 8,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.copy, size: 14, color: AppColors.textSecondary),
                                  SizedBox(width: 4),
                                  Text('Toca para copiar', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Envíaselo a tu pareja para que lo introduzca en su app.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.like),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Esperando a tu pareja…',
                            style: TextStyle(color: AppColors.like, fontSize: 13),
                          ),
                        ],
                      ),
                    ],

                    // --- DIVISOR ---
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        const Expanded(child: Divider(color: AppColors.surfaceBorder)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('o', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                        ),
                        const Expanded(child: Divider(color: AppColors.surfaceBorder)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // --- SECCIÓN 2: Meter un código ---
                    const Text(
                      '¿Te han enviado un código?',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _joinController,
                      textCapitalization: TextCapitalization.characters,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      style: const TextStyle(fontSize: 24, letterSpacing: 6, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Código de invitación',
                        counterText: '',
                        hintText: 'ABC123',
                        hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.3), letterSpacing: 6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.surfaceBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.surfaceBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.like),
                        ),
                      ),
                    ),
                    if (_joinError != null) ...[
                      const SizedBox(height: 8),
                      Text(_joinError!, style: const TextStyle(color: AppColors.like, fontSize: 13)),
                    ],
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: 'Unirme',
                      isLoading: _joining,
                      onPressed: _joinWithCode,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
