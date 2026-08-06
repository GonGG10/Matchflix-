import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../rooms/data/rooms_repository.dart';
import '../../../core/network/core_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isCreating = false;
  bool _isSyncing = false;
  String? _syncMessage;

  Future<void> _createRoom() async {
    setState(() => _isCreating = true);
    try {
      final repo = ref.read(roomsRepositoryProvider);
      final data = await repo.createRoom();
      if (mounted) {
        context.go('/room/code', extra: {
          'inviteCode': data['inviteCode'],
          'expiresAt': data['expiresAt'],
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo crear la sala. Inténtalo de nuevo.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _syncCatalog() async {
    setState(() { _isSyncing = true; _syncMessage = null; });
    try {
      final repo = ref.read(roomsRepositoryProvider);
      final result = await repo.syncCatalog(force: true);
      final processed = result['titlesProcessed'] ?? 0;
      setState(() {
        _syncMessage = processed > 0
            ? 'Catálogo actualizado: $processed títulos'
            : 'El catálogo ya está actualizado';
      });
    } catch (e) {
      setState(() => _syncMessage = 'Error al actualizar. Inténtalo más tarde.');
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 16, left: 16,
              child: _SyncButton(isSyncing: _isSyncing, message: _syncMessage, onPressed: _syncCatalog),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.asset('assets/images/logo.png', width: 120, height: 120, fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 20),
                    const Text('MatchFlix', textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                    const SizedBox(height: 6),
                    const Text('Encuentra qué ver, juntos', textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                    const SizedBox(height: 56),
                    _PrimaryButton(label: 'Crear sala', icon: Icons.add_circle_outline_rounded, isLoading: _isCreating, onPressed: _createRoom),
                    const SizedBox(height: 16),
                    _SecondaryButton(label: 'Tengo un código', icon: Icons.keyboard_rounded, onPressed: () => context.go('/room/join')),
                    const SizedBox(height: 40),
                    const Text('Las salas duran 15 minutos.\nCrea una sala, comparte el código con tu pareja y empezad a deslizar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.5)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncButton extends StatelessWidget {
  const _SyncButton({required this.isSyncing, required this.message, required this.onPressed});
  final bool isSyncing;
  final String? message;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceBorder, width: 1),
          ),
          child: IconButton(
            icon: isSyncing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.like))
                : const Icon(Icons.cloud_sync_rounded, color: AppColors.textSecondary, size: 22),
            onPressed: isSyncing ? null : onPressed,
            tooltip: 'Actualizar catálogo',
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 6),
          Text(message!, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ],
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.icon, required this.isLoading, required this.onPressed});
  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFF5D73), Color(0xFFFF8A5C)], begin: Alignment.centerLeft, end: Alignment.centerRight),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: const Color(0xFFFF5D73).withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 6))],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(icon, color: Colors.white, size: 24),
                  const SizedBox(width: 10),
                  Text(label, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                ]),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.icon, required this.onPressed});
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.surfaceBorder, width: 1.5),
        ),
        child: Center(
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: AppColors.textPrimary, size: 22),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }
}
