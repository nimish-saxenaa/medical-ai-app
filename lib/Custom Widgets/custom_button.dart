import 'package:flutter/material.dart';
import 'package:clinical_ai_app/Components/colors.dart';
class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isPseudoDisabled = false,
    this.isLoading = false,
  });
  final VoidCallback? onPressed;
  final Widget child;
  final bool isPseudoDisabled;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    ButtonStyle? style;
    if (isLoading) {
      style = ElevatedButton.styleFrom(
        disabledBackgroundColor: isDark ? AppDarkColors.brand : AppColors.brand,
        disabledForegroundColor: isDark ? AppDarkColors.textPrimary : AppColors.surface,
      );
    } else if (isPseudoDisabled) {
      style = ElevatedButton.styleFrom(
        backgroundColor: isDark ? const Color(0xFF2C2745) : const Color(0xFFE5E7EB),
        foregroundColor: isDark ? const Color(0xFF9691AD) : const Color(0xFF9CA3AF),
        elevation: 0,
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onPressed,
            style: style,
            child: child,
          ),
        ),
      ),
    );
  }
}
