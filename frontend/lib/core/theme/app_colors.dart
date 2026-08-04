import 'package:flutter/material.dart';

/// Paleta propia: sala de cine + calidez de pareja.
/// Fondo casi negro con un leve tinte violeta-azulado (no un negro plano
/// genérico), acento coral-rosa para "me gusta"/match (deliberadamente
/// distinto del rojo de Netflix) y dorado suave para valoraciones.
class AppColors {
  AppColors._();

  static const background = Color(0xFF0E0E16);
  static const surface = Color(0xFF191922);
  static const surfaceElevated = Color(0xFF23232F);
  static const surfaceBorder = Color(0xFF2E2E3B);

  static const like = Color(0xFFFF5D73); // coral-rosa
  static const dislike = Color(0xFF6C7086); // slate apagado
  static const matchGold = Color(0xFFE8B44C);

  static const textPrimary = Color(0xFFF5F5F7);
  static const textSecondary = Color(0xFFA0A0AD);
  static const textMuted = Color(0xFF6D6D7A);

  static const gradientMatch = LinearGradient(
    colors: [Color(0xFFFF5D73), Color(0xFFE8B44C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
