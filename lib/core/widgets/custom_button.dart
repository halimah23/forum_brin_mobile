import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../constants/app_typography.dart';

enum CustomButtonVariant { primary, outlined, ghost }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final CustomButtonVariant variant;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final double height;
  final double borderRadius;
  final Widget? icon;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.variant = CustomButtonVariant.primary,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.height = 48.0,
    this.borderRadius = AppRadius.md,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    BorderSide border;

    switch (variant) {
      case CustomButtonVariant.primary:
        bg = backgroundColor ?? AppColors.primaryRed;
        fg = textColor ?? AppColors.textOnPrimary;
        border = BorderSide.none;
        break;
      case CustomButtonVariant.outlined:
        bg = backgroundColor ?? Colors.transparent;
        fg = textColor ?? AppColors.slate700;
        border = BorderSide(
          color: borderColor ?? AppColors.slate300,
          width: 1.0,
        );
        break;
      case CustomButtonVariant.ghost:
        bg = backgroundColor ?? Colors.transparent;
        fg = textColor ?? AppColors.primaryRed;
        border = BorderSide.none;
        break;
    }

    final childWidget = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: fg,
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                IconTheme(
                  data: IconThemeData(color: fg, size: 18),
                  child: icon!,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: AppTypography.button.copyWith(color: fg),
              ),
            ],
          );

    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: AppColors.slate200,
          disabledForegroundColor: AppColors.slate400,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: border,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: childWidget,
      ),
    );
  }
}
