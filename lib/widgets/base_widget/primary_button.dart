import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final String title;
  final VoidCallback? onPressed; // Nullable for disabled state
  final bool isDisabled;
  final bool? isOutlined;

  const PrimaryButton({
    super.key,
    required this.title,
    required this.onPressed,
    this.isDisabled = false,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ElevatedButton(
      onPressed: isDisabled ? null : onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor:
            isDisabled ? theme.colorScheme.onSurfaceVariant : Colors.white,
        minimumSize: const Size(double.infinity, 50),
        elevation: isDisabled ? 0 : 4,
      ),
      child: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: isDisabled ? theme.colorScheme.onSurfaceVariant : Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
