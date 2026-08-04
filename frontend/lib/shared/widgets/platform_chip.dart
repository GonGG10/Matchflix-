import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Chip con el nombre de la plataforma. Si el proveedor no trae logotipo
/// (posterUrl nulo), se degrada con elegancia a un chip de texto en vez de
/// romper el diseño.
class PlatformChip extends StatelessWidget {
  const PlatformChip({super.key, required this.name, this.logoUrl});
  final String name;
  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Text(
        name,
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
