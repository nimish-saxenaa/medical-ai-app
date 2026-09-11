import 'package:clinical_ai_app/Components/layout_constants.dart';
import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    required this.hintText,
    this.obscureText = false,
    required this.controller,
    required this.fieldName,
    this.keyboardType,
  });
  final String fieldName;
  final String hintText;
  final bool obscureText;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          fieldName,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppLayout.space8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          decoration: InputDecoration(
            fillColor: Theme.of(context).colorScheme.surface,
            hintText: hintText,
            hintStyle: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
            contentPadding: const EdgeInsets.symmetric(horizontal: AppLayout.space16, vertical: AppLayout.space12 + 2),
          ),
        ),
      ],
    );
  }
}
