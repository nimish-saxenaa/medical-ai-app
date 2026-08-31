import 'package:clinical_ai_app/Components/layout_constants.dart';
import 'package:clinical_ai_app/Custom%20Widgets/custom_button.dart';
import 'package:flutter/material.dart';
import '../Components/colors.dart';

Future<dynamic> showCustomDialog(String detail, BuildContext context) {
  final theme = Theme.of(context);
  return showDialog(
    context: context,
    barrierColor: AppColors.textPrimary.withAlpha(100),
    builder: (context) {
      return Dialog(
        backgroundColor: theme.scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppLayout.radius16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: AppLayout.space16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(AppLayout.space16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(detail, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: AppLayout.space16),
                CustomButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
