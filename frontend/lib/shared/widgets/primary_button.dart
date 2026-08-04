import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.filled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            height: 20, width: 20,
            child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
          )
        : Text(label);

    if (!filled) {
      return OutlinedButton(onPressed: isLoading ? null : onPressed, child: child);
    }
    return ElevatedButton(onPressed: isLoading ? null : onPressed, child: child);
  }
}
