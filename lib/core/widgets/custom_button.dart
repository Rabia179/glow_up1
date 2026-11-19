import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum CustomButtonType { primary, secondary, outline }

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final CustomButtonType type;
  final IconData? icon;
  final bool fullWidth;
  final double height;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.type = CustomButtonType.primary,
    this.icon,
    this.fullWidth = false,
    this.height = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    BorderSide borderSide = BorderSide.none;

    switch (type) {
      case CustomButtonType.primary:
        backgroundColor = AppColors.primary;
        textColor = AppColors.onPrimary;
        break;
      case CustomButtonType.secondary:
        backgroundColor = AppColors.secondaryContainer;
        textColor = AppColors.onSecondaryContainer;
        break;
      case CustomButtonType.outline:
        backgroundColor = Colors.transparent;
        textColor = AppColors.primary;
        borderSide = const BorderSide(color: AppColors.primary, width: 1.5);
        break;
    }

    final Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.labelLg(color: textColor).copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        if (icon != null) ...[
          const SizedBox(width: 8),
          Icon(icon, size: 18, color: textColor),
        ],
      ],
    );

    return SizedBox(
      height: height,
      width: fullWidth ? double.infinity : null,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: type == CustomButtonType.primary ? 4 : 0,
          shadowColor: AppColors.primary.withValues(alpha: 0.25),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9999), // full pill radius
            side: borderSide,
          ),
        ),
        onPressed: onPressed,
        child: content,
      ),
    );
  }
}
