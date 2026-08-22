import 'package:clinical_ai_app/Custom%20Widgets/custom_button.dart';
import 'package:flutter/material.dart';
import '../Components/colors.dart';

Future<dynamic> showCustomDialog(String detail, BuildContext context) {
  return showDialog(
    context: context,
    barrierColor: AppColors.textPrimary.withAlpha(100),
    builder: (context) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(detail, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 16),
                CustomButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("OK"),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
