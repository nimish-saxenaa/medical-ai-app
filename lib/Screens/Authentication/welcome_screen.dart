import 'package:clinical_ai_app/Screens/Authentication/login_screen.dart';
import 'package:flutter/material.dart';

import '../../Components/colors.dart';
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
                  horizontal: isTablet ? 40 : 24,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentWidth),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: isTablet ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                    children: [
                      LogoAndText(width: isTablet ? 600 : constraints.maxWidth),
                      
                      const SizedBox(height: 32),
                      
                      Text(
                        "Smarter histories.\nBetter outcomes.",
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontSize: isTablet ? 42 : 32,
                        ),
                        textAlign: isTablet ? TextAlign.center : TextAlign.left,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Text(
                        "AI-powered medical history taking that helps you diagnose with confidence and document without the burden.",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: isTablet ? 18 : 16,
                          height: 1.5,
                        ),
                        textAlign: isTablet ? TextAlign.center : TextAlign.left,
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Features list
                      Column(
                        children: const [
                          IconText(text: "Structured patient history in under 5 minutes"),
                          SizedBox(height: 16),
                          IconText(text: "AI-generated differential diagnoses"),
                          SizedBox(height: 16),
                          IconText(text: "Instant SOAP note documentation"),
                        ],
                      ),
                      
                      const SizedBox(height: 56),
                      
                      CustomButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                        child: const Text('Get Started'),
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

class IconText extends StatelessWidget {
  const IconText({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text, 
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
