import 'dart:async';
import 'package:clinical_ai_app/Components/layout_constants.dart';
import 'package:flutter/material.dart';

Future<dynamic> showCustomConfirmationAlert({
  required String detail,
  required BuildContext context,
  required FutureOr<void> Function() onPressed,
  String title = "Confirm Action",
  String confirmText = "Confirm",
  String? loadingText,
  Color? confirmColor,
}) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final effectiveConfirmColor = confirmColor ?? theme.colorScheme.primary;

  return showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withAlpha(150),
    builder: (context) {
      bool isLoading = false;
      return StatefulBuilder(
        builder: (context, setState) {
          return PopScope(
            canPop: !isLoading,
            child: Dialog(
            backgroundColor: theme.scaffoldBackgroundColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppLayout.radius16)),
            insetPadding: const EdgeInsets.symmetric(horizontal: AppLayout.space16),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
              child: Padding(
                padding: const EdgeInsets.all(AppLayout.space20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.displayMedium,
                    ),
                    const SizedBox(height: AppLayout.space12),
                    Text(
                      detail,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppLayout.space12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isLoading ? null : () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.surface,
                              foregroundColor: theme.colorScheme.onSurface,
                              padding: const EdgeInsets.symmetric(vertical: AppLayout.space12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppLayout.radius10),
                                side: BorderSide(color: theme.dividerColor),
                              ),
                            ),
                            child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: AppLayout.space12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (isLoading) return;
                              if (loadingText != null) {
                                setState(() => isLoading = true);
                                try {
                                  await onPressed();
                                } finally {
                                  if (context.mounted) {
                                    setState(() => isLoading = false);
                                    // Use maybePop to safely handle cases where the stack might have been cleared (e.g. logout)
                                    Navigator.of(context).maybePop();
                                  }
                                }
                              } else {
                                // Pop the dialog before running the action to avoid it staying on screen
                                Navigator.of(context).maybePop();
                                onPressed();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: effectiveConfirmColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: AppLayout.space12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppLayout.radius10)),
                            ),
                            child: (isLoading && loadingText != null)
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          loadingText,
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(confirmText, style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
