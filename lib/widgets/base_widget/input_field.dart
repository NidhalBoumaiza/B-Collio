import 'package:flutter/material.dart';

class StyledInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData? icon; // Make icon optional
  final String? imagePath; // Add imagePath parameter
  final TextInputType inputType;
  final Widget? trailing;
  final bool obscureText;
  final ValueChanged<String>? onChanged; // Optional onChanged callback
  final bool? enabled; // Optional enabled parameter

  const StyledInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.icon, // Make icon optional
    this.imagePath, // Add imagePath parameter
    this.inputType = TextInputType.text,
    this.trailing,
    this.obscureText = false,
    this.onChanged, // Make onChanged optional
    this.enabled, // Make enabled optional
  }) : assert(icon != null || imagePath != null,
            'Either icon or imagePath must be provided.');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Display either the icon or the image
          if (icon != null)
            Icon(icon, color: theme.colorScheme.primary)
          else if (imagePath != null)
            Image.asset(
              imagePath!,
              width: 30, // Adjust the size as needed
              height: 30, // Adjust the size as needed
            ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: inputType,
              obscureText: obscureText,
              onChanged: onChanged, // Pass onChanged to TextField
              enabled: enabled, // Pass enabled to TextField
              decoration: InputDecoration(
                labelText: label,
                hintText: hint,
                border: InputBorder.none,
                labelStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.inputDecorationTheme.hintStyle?.color,
                  fontWeight: FontWeight.bold,
                ),
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
