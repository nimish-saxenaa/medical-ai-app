import 'package:clinical_ai_app/Screens/Authentication/create_account_screen.dart';
import 'package:clinical_ai_app/Screens/PatientData/home_screen.dart';
import 'package:clinical_ai_app/Services/Authentication/auth_service.dart';
import 'package:clinical_ai_app/Services/Authentication/navigation_service.dart';
import 'package:clinical_ai_app/Services/PatientData/patient_service.dart';
import 'package:clinical_ai_app/Services/Authentication/access_token.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Custom Widgets/CustomAlertDialog.dart';
import '../../Custom Widgets/custom_button.dart';
import '../../Custom Widgets/custom_text_field.dart';
import '../../Custom Widgets/logo_text.dart';
import '../../Models/patient_list_model.dart';
import '../../Components/colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  static const routeName = "/login";

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    emailController.dispose();
    passwordController.dispose();
  }

  bool isTapped = false;

  @override
  Widget build(BuildContext context) {
    final patientsProvider = context.read<PatientListProvider>();
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isTablet = constraints.maxWidth > 600;
            double contentWidth = isTablet ? 450 : double.infinity;

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
                        'Welcome back.',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontSize: isTablet ? 36 : 28,
                        ),
                        textAlign: isTablet ? TextAlign.center : TextAlign.left,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        'Sign in to your account to continue.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.greyDark,
                          fontSize: isTablet ? 18 : 16,
                        ),
                        textAlign: isTablet ? TextAlign.center : TextAlign.left,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      CustomTextField(
                        hintText: 'doctor@hospital.com',
                        controller: emailController,
                        fieldName: "Email address",
                        keyboardType: TextInputType.emailAddress,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      CustomTextField(
                        hintText: '••••••••',
                        controller: passwordController,
                        fieldName: 'Password',
                        obscureText: true,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      CustomButton(
                        onPressed: () async {
                          if (emailController.text.isEmpty || !emailController.text.contains("@")) {
                            if (!context.mounted) return;
                            showCustomDialog("Enter a valid Email", context);
                            return;
                          } else if (passwordController.text.isEmpty) {
                            if (!context.mounted) return;
                            showCustomDialog("Enter a valid Password", context);
                            return;
                          }
                          
                          setState(() {
                            isTapped = true;
                          });
                          
                          try {
                            var response = await login(
                              email: emailController.text,
                              password: passwordController.text,
                            );
                            
                            if (response['access_token'] != null) {
                              AccessTokenService.saveAccessToken(response['access_token']);
                              AccessTokenService.saveRefreshToken(response['refresh_token']);
                              PatientListProvider? patientList = await listPatients();
                              patientsProvider.setPatients(patientList.patients!);
                              
                              navigatorKey.currentState?.pushNamedAndRemoveUntil(
                                HomeScreen.routeName,
                                (route) => false,
                              );
                            } else {
                              setState(() {
                                isTapped = false;
                              });
                              if (!context.mounted) return;
                              showCustomDialog(response['detail'].toString(), context);
                            }
                          } catch (e) {
                            setState(() {
                              isTapped = false;
                            });
                            if (!context.mounted) return;
                            showCustomDialog(
                              "Connection error. Please check your internet or try again later.",
                              context,
                            );
                          }
                          
                          if (mounted) {
                            setState(() {
                              isTapped = false;
                            });
                          }
                        },
                        child: isTapped
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text('Signing in...'),
                                ],
                              )
                            : const Text('Sign in'),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      Center(
                        child: RichText(
                          text: TextSpan(
                            text: "New here?",
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.grey,
                              fontSize: isTablet ? 16 : 14,
                            ),
                            children: [
                              TextSpan(
                                text: " Create an Account",
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppColors.primary,
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