import 'package:clinical_ai_app/Components/layout_constants.dart';
import 'package:clinical_ai_app/Screens/Authentication/login_screen.dart';
import 'package:flutter/material.dart';

import '../../Custom Widgets/custom_button.dart';
import '../../Custom Widgets/logo_text.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  static const routeName = "/welcome";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isTablet = constraints.maxWidth > 600;
            double contentWidth = isTablet ? 500 : double.infinity;

            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? AppLayout.space40 : AppLayout.space24,
                  vertical: AppLayout.space32,
                ),
                child: Container(
                  constraints: BoxConstraints(maxWidth: contentWidth),
                  padding: isTablet ? const EdgeInsets.all(AppLayout.space40) : EdgeInsets.zero,
                  decoration: isTablet ? BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(AppLayout.panelRadius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(Theme.of(context).brightness == Brightness.light ? 15 : 40),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: Theme.of(context).dividerColor, width: AppLayout.borderThin),
                  ) : null,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: isTablet ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                    children: [
                      LogoAndText(width: isTablet ? 600 : constraints.maxWidth),
                      
                      const SizedBox(height: AppLayout.space32),
                      
                      Text(
                        "Smarter histories.\nBetter outcomes.",
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontSize: isTablet ? 42 : 32,
                        ),
                        textAlign: isTablet ? TextAlign.center : TextAlign.left,
                      ),
                      
                      const SizedBox(height: AppLayout.space16),
                      
                      Text(
                        "AI-powered medical history taking that helps you diagnose with confidence and document without the burden.",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: isTablet ? 18 : 16,
                          height: 1.5,
                        ),
                        textAlign: isTablet ? TextAlign.center : TextAlign.left,
                      ),
                      
                      const SizedBox(height: AppLayout.space40),
                      
                      // Features list
                      Column(
                        children: const [
                          FeatureBubble(text: "Structured patient history in under 5 minutes"),
                          SizedBox(height: AppLayout.space12),
                          FeatureBubble(text: "AI-generated differential diagnoses"),
                          SizedBox(height: AppLayout.space12),
                          FeatureBubble(text: "Instant SOAP note documentation"),
                        ],
                      ),
                      
                      const SizedBox(height: AppLayout.space56),
                      
                      CustomButton(
                        text: 'Get Started',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class FeatureBubble extends StatelessWidget {
  const FeatureBubble({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppLayout.space16, vertical: AppLayout.space12 + 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppLayout.radius16),
        border: Border.all(color: theme.colorScheme.primaryContainer, width: AppLayout.borderThin),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: theme.colorScheme.primary,
            size: AppLayout.iconMedium + 2,
          ),
          const SizedBox(width: AppLayout.space12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
