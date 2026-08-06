import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/core_providers.dart';

class RoomCodeScreen extends ConsumerStatefulWidget {
  const RoomCodeScreen({super.key});
  @override
  ConsumerState<RoomCodeScreen> createState() => _RoomCodeScreenState();
}

class _RoomCodeScreenState extends ConsumerState<RoomCodeScreen> {
  Timer? _pollTimer;
  String _inviteCode = '';
  String _expiresAt = '';
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    if (extra != null) {
      _inviteCode = extra['inviteCode'] as String? ?? '';
      _expiresAt = extra['expiresAt'] as String? ?? '';
    }
    _startPolling();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _checkStatus());
  }

  Future<void> _checkStatus() async {
    if (_checking) return;
    _checking = true;
    try {
      final repo = ref.read(roomsRepositoryProvider);
      final status = await repo.getRoomStatus();
      if (!mounted) return;
      final s = status['status'] as String?;
      if (s == 'ACTIVE') {
        _pollTimer?.cancel();
        context.go('/categories');
      } else if (s == 'EXPIRED' || s == 'NONE') {
        _pollTimer?.cancel();
        context.go('/');
      }
    } catch (_) {}
    _checking = false;
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  String get _remainingTime {
    if (_expiresAt.isEmpty) return '';
    final expiry = DateTime.parse(_expiresAt);
    final remaining = expiry.difference(DateTime.now());
    if (remaining.isNegative) return 'Expirada';
    final m = remaining.inMinutes;
    final s = remaining.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
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
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset('assets/images/logo.png', width: 72, height: 72, fit: BoxFit.cover),
                ),
                const SizedBox(height: 24),
                const Text('Tu código de sala', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.like.withOpacity(0.4), width: 2),
                  ),
                  child: GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: _inviteCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Código copiado'), duration: Duration(seconds: 1)),
                      );
                    },
                    child: Text(
                      _inviteCode,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tiempo restante: $_remainingTime',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 32),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.like)),
                    SizedBox(width: 12),
                    Text('Esperando a tu pareja...', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 40),
                TextButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
