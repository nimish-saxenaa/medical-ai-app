import 'package:clinical_ai_app/Screens/Authentication/login_screen.dart';
import 'package:clinical_ai_app/Services/Authentication/auth_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../Custom Widgets/CustomAlertDialog.dart';
import '../../Custom Widgets/custom_button.dart';
import '../../Custom Widgets/custom_text_field.dart';
import '../../Custom Widgets/logo_text.dart';
import '../../Models/patient_list_model.dart';
import '../../Services/Authentication/navigation_service.dart';
import '../../Services/PatientData/patient_service.dart';
import '../../Services/Authentication/access_token.dart';
import '../../Components/colors.dart';
import '../PatientData/home_screen.dart';
import 'package:provider/provider.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});
  static const routeName = "/create-account";

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final TextEditingController nameController = TextEditingController();

  final TextEditingController emailController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

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
                        'Create Your Account',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontSize: isTablet ? 36 : 28,
                        ),
                        textAlign: isTablet ? TextAlign.center : TextAlign.left,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        'Start taking smarter clinical histories today.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.greyDark,
                          fontSize: isTablet ? 18 : 16,
                        ),
                        textAlign: isTablet ? TextAlign.center : TextAlign.left,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      CustomTextField(
                        hintText: 'Dr. Priya Sharma',
                        controller: nameController,
                        fieldName: "Full Name",
                      ),
                      
                      const SizedBox(height: 16),
                      
                      CustomTextField(
                        hintText: 'dr@hospital.com',
                        controller: emailController,
                        fieldName: "Email address",
                        keyboardType: TextInputType.emailAddress,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      CustomTextField(
                        hintText: 'Min. 8 characters',
                        controller: passwordController,
                        fieldName: 'Password',
                        obscureText: true,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      CustomButton(
                        onPressed: () async {
                          if (nameController.text.isEmpty) {
                            if (!context.mounted) return;
                            showCustomDialog("Enter a valid Name", context);
                            return;
                          } else if (emailController.text.isEmpty || !emailController.text.contains("@")) {
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
                            var response = await createAccount(
                              name: nameController.text,
                              email: emailController.text,
                              password: passwordController.text,
                            );
                            
                            if (response['access_token'] != null) {
                              AccessTokenService.saveAccessToken(response['access_token']);
                              AccessTokenService.saveRefreshToken(response['refresh_token']);
                              PatientListProvider? patientList = await listPatients();
                              patientsProvider.setPatients(patientList.patients!);
                              
                              if (!context.mounted) return;
                              navigatorKey.currentState?.pushNamedAndRemoveUntil(
                                HomeScreen.routeName,
                                (route) => false,
                              );
                            } else {
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
                                  Text('Creating Account...'),
                                ],
                              )
                            : const Text('Create Account'),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      Center(
                        child: RichText(
                          text: TextSpan(
                            text: "Already have an Account?",
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.grey,
                              fontSize: isTablet ? 16 : 14,
                            ),
                            children: [
                              TextSpan(
                                text: " Sign In",
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
                                        builder: (_) => const LoginScreen(),
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
