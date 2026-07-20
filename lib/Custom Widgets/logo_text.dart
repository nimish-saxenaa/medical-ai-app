import 'package:flutter/material.dart';

class LogoAndText extends StatelessWidget {
  const LogoAndText({super.key, required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32.0),
      child: Center(
        child: Column(
          children: [
            Image(
              image: const AssetImage('assets/kuvaka_logo.png'),
              width: width / 6,
            ),
            const SizedBox(height: 8),
            Text(
              "Clinical AI platform by Kuvaka".toUpperCase(),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
