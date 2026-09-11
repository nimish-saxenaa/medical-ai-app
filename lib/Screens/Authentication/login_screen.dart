import 'package:clinical_ai_app/Services/Authentication/auth_service.dart';
import 'package:clinical_ai_app/Services/Authentication/navigation_service.dart';
import 'package:clinical_ai_app/Services/PatientData/patient_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Components/layout_constants.dart';
import '../../Custom Widgets/custom_button.dart';
import '../../Custom Widgets/custom_text_field.dart';
import '../../Custom Widgets/logo_text.dart';
import '../../Models/patient_list_model.dart';
import '../../Components/colors.dart';
import '../PatientData/home_screen.dart';
import 'create_account_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  static const routeName = "/login";

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String? errorMessage;
  bool isTapped = false;

  @override
  void initState() {
    super.initState();
    emailController.addListener(_validateForm);
    passwordController.addListener(_validateForm);
  }

  void _validateForm() {
    setState(() {
      errorMessage = null; // Clear error when typing
    });
  }

  bool get _isFormValid {
    final email = emailController.text.trim();
    final password = passwordController.text;
    
    // Basic email validation: something@something
    final emailValid = email.contains('@') && 
                       email.indexOf('@') > 0 && 
                       email.indexOf('@') < email.length - 1;
    
    return emailValid && password.isNotEmpty;
  }

  void _showValidationError() {
    final email = emailController.text.trim();
    final password = passwordController.text;
    final emailValid = email.contains('@') &&
        email.indexOf('@') > 0 &&
        email.indexOf('@') < email.length - 1;

    setState(() {
      if (email.isEmpty && password.isEmpty) {
        errorMessage = "Email and Password are required.";
      } else if (email.isEmpty) {
        errorMessage = "Email address is required.";
      } else if (!emailValid) {
        errorMessage = "Please enter a valid email address (e.g., name@company.com).";
      } else if (password.isEmpty) {
        errorMessage = "Password is required.";
      }
    });
  }

  @override
  void dispose() {
    emailController.removeListener(_validateForm);
    passwordController.removeListener(_validateForm);
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patientsProvider = context.read<PatientListProvider>();
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isTablet = constraints.maxWidth > 600;
            double contentWidth = isTablet ? 450 : double.infinity;

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
                        'Welcome back.',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontSize: isTablet ? 36 : 28,
                        ),
                        textAlign: isTablet ? TextAlign.center : TextAlign.left,
                      ),

                      const SizedBox(height: AppLayout.space8),

                      Text(
                        'Sign in to your account to continue.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontSize: isTablet ? 18 : 16,
                        ),
                        textAlign: isTablet ? TextAlign.center : TextAlign.left,
                      ),

                      const SizedBox(height: AppLayout.space32),

                      CustomTextField(
                        hintText: 'doctor@hospital.com',
                        controller: emailController,
                        fieldName: "Email Address",
                        keyboardType: TextInputType.emailAddress,
                      ),

                      const SizedBox(height: AppLayout.space16),

                      CustomTextField(
                        hintText: '••••••••',
                        controller: passwordController,
                        fieldName: 'Password',
                        obscureText: true,
                      ),

                      const SizedBox(height: AppLayout.space16),

                      if (errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Center(
                            child: Text(
                              errorMessage!,
                              style: const TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      else
                        const SizedBox(height: AppLayout.space16),

                      CustomButton(
                        text: 'Sign in',
                        loadingText: 'Signing in...',
                        isPseudoDisabled: !_isFormValid,
                        onTap: () async {
                          if (!_isFormValid) {
                            _showValidationError();
                            return;
                          }

                          setState(() {
                            errorMessage = null;
                          });

                          try {
                            var response = await login(
                              email: emailController.text.trim(),
                              password: passwordController.text,
                            );

                            if (response['access_token'] != null) {
                              PatientListProvider? patientList = await listPatients();
                              patientsProvider.setPatients(patientList.patients!);

                              navigatorKey.currentState?.pushNamedAndRemoveUntil(
                                HomeScreen.routeName,
                                (route) => false,
                              );
                            } else {
                              setState(() {
                                errorMessage = response['detail']?.toString() ?? "Login failed";
                              });
                            }
                          } catch (e) {
                            setState(() {
                              errorMessage = "Connection error. Please check your internet or try again later.";
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 24),

                      Center(
                        child: RichText(
                          text: TextSpan(
                            text: "New here?",
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).textTheme.bodySmall?.color,
                              fontSize: isTablet ? 16 : 14,
                            ),
                            children: [
                              TextSpan(
                                text: " Create an Account",
                                style: const TextStyle(
                                  color: AppColors.brand,
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppColors.brand,
                                  fontWeight: FontWeight.bold,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const CreateAccountScreen(),
                                      ),
                                    );
                                  },
                              ),
                            ],
                          ),
                        ),
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