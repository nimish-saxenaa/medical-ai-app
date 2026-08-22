import 'package:flutter/material.dart';
import '../Components/colors.dart';

Future<dynamic> showCustomConfirmationAlert({
  required String detail,
  required BuildContext context,
  required VoidCallback onPressed,
  String title = "Confirm Action",
  String confirmText = "Confirm",
  Color? confirmColor,
}) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final effectiveConfirmColor = confirmColor ?? theme.colorScheme.primary;

  return showDialog(
    context: context,
    barrierColor: Colors.black.withAlpha(150),
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
                ),
                const SizedBox(height: 12),
                Text(
                  detail,
                  style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color, height: 1.5),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? theme.scaffoldBackgroundColor : AppColors.background,
                          foregroundColor: isDark ? Colors.white : theme.textTheme.bodyMedium?.color,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: theme.dividerColor),
                          ),
                        ),
                        child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: effectiveConfirmColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(confirmText, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
