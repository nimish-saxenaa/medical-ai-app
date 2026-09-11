import 'dart:async';
import 'package:flutter/material.dart';
import 'package:clinical_ai_app/Components/colors.dart';

typedef CustomButtonCallback = FutureOr<void> Function();

class CustomButton extends StatefulWidget {
  const CustomButton({
    super.key,
    required this.text,
    required this.onTap,
    this.loadingText,
    this.isPseudoDisabled = false,
  });

  final String text;
  final CustomButtonCallback? onTap;
  final String? loadingText;
  final bool isPseudoDisabled;

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _isLoading = false;

  void _handleTap() async {
    if (_isLoading || widget.onTap == null) return;

    final result = widget.onTap!();
    if (result is Future) {
      setState(() => _isLoading = true);
      try {
        await result;
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    ButtonStyle? style;
    if (_isLoading) {
      style = ElevatedButton.styleFrom(
        disabledBackgroundColor: isDark ? AppDarkColors.brand : AppColors.brand,
        disabledForegroundColor: isDark ? AppDarkColors.textPrimary : AppColors.surface,
      );
    } else if (widget.isPseudoDisabled) {
      style = ElevatedButton.styleFrom(
        backgroundColor: isDark ? AppDarkColors.outlineVariant : AppColors.outlineVariant,
        foregroundColor: isDark ? AppDarkColors.textDisabled : AppColors.textDisabled,
        elevation: 0,
      );
    }

    Widget content;
    if (_isLoading) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: isDark ? AppDarkColors.textPrimary : AppColors.surface,
            ),
          ),
          if (widget.loadingText != null && widget.loadingText!.isNotEmpty) ...[
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                widget.loadingText!,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      );
    } else {
      content = Text(
        widget.text,
        textAlign: TextAlign.center,
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleTap,
            style: style,
            child: content,
          ),
        ),
      ),
    );
  }
}
