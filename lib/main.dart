import 'package:audioplayers/audioplayers.dart';
import 'package:clinical_ai_app/Screens/Authentication/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'Components/app_theme.dart';
import 'Models/patient_list_model.dart';
import 'Screens/Authentication/create_account_screen.dart';
import 'Screens/PatientData/home_screen.dart';
import 'Screens/Consultation/review_responses_screen.dart';
import 'Screens/Authentication/welcome_screen.dart';
import 'Services/Authentication/auth_service.dart';
import 'Services/Authentication/navigation_service.dart';
import 'Services/PatientData/patient_service.dart';
import 'Services/Authentication/access_token.dart';
import 'Screens/Consultation/cabin_consultation_screen.dart';
import 'package:device_preview/device_preview.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AudioPlayer.global.setAudioContext(
    AudioContext(
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playAndRecord,
        options: const {
          AVAudioSessionOptions.defaultToSpeaker,
          AVAudioSessionOptions.allowBluetooth,
          AVAudioSessionOptions.allowBluetoothA2DP,
        },
      ),
      android: AudioContextAndroid(
        isSpeakerphoneOn: true,
        stayAwake: true,
        contentType: AndroidContentType.speech,
        usageType: AndroidUsageType.assistant,
        audioFocus: AndroidAudioFocus.gainTransientMayDuck,
      ),
    ),
  );
  runApp(
    DevicePreview(
      enabled: true,
      tools: const [
        ...DevicePreview.defaultTools,
      ],
      builder: (context) => ChangeNotifierProvider(
        create: (_) => PatientListProvider(),
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AuthGate.routeName,
      routes: {
        CreateAccountScreen.routeName: (context) => CreateAccountScreen(),
        LoginScreen.routeName: (context) => LoginScreen(),
        HomeScreen.routeName: (context) => HomeScreen(),
        WelcomeScreen.routeName: (context) => WelcomeScreen(),
        AuthGate.routeName: (context) => AuthGate(),
        ReviewResponsesScreen.routeName: (context) => ReviewResponsesScreen(
              token: '',
              sessionId: '',
            ),
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  static const routeName = "/auth-gate";
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Future<void> _checkAuth(BuildContext context) async {
    final refreshToken = await AccessTokenService.getRequestToken();

    if (refreshToken == null || refreshToken.isEmpty) {
      _goTo(const WelcomeScreen());
      return;
    }

    try {
      final result = await refreshTokens();

      final newAccessToken = result['access_token'] ?? result['accessToken'];
      final newRefreshToken = result['refresh_token'] ?? result['refreshToken'];

      if (newAccessToken != null && newRefreshToken != null) {
        await AccessTokenService.saveAccessToken(newAccessToken.toString());
        await AccessTokenService.saveRefreshToken(newRefreshToken.toString());
      }
      if (!context.mounted) return;
      final patientsProvider = context.read<PatientListProvider>();
      PatientListProvider patientList = await listPatients();

      patientsProvider.setPatients(patientList.patients!);
      _goTo(const HomeScreen());
    } catch (_) {
      await AccessTokenService.clear();
      _goTo(const WelcomeScreen());
    }
  }

  void _goTo(Widget screen) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    _checkAuth(context);
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
