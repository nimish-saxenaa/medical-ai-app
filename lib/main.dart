import 'package:audioplayers/audioplayers.dart';
import 'package:clinical_ai_app/Components/layout_constants.dart';
import 'package:clinical_ai_app/Screens/Authentication/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    hide ChangeNotifierProvider;
import 'Components/app_theme.dart';
import 'Custom Widgets/home_skeleton.dart';
import 'Models/patient_list_model.dart';
import 'Screens/Authentication/create_account_screen.dart';
import 'Screens/PatientData/home_screen.dart';
import 'Screens/Consultation/review_responses_screen.dart';
import 'Screens/Authentication/welcome_screen.dart';
import 'Services/Authentication/auth_service.dart';
import 'Services/Authentication/navigation_service.dart';
import 'Services/Authentication/access_token.dart';

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
    /*DevicePreview(
      enabled: true,
      tools: const [
        ...DevicePreview.defaultTools,
      ],
      builder: (context) => ChangeNotifierProvider(
        create: (_) => PatientListProvider(),
        child: const MyApp(),
      ),
    ),*/
    ProviderScope(
      child: ChangeNotifierProvider(
        create: (_) => PatientListProvider(),
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Requirements Part 7: Check token on app resume
      _checkTokenOnResume();
    }
  }

  Future<void> _checkTokenOnResume() async {
    try {
      final token = await TokenManager.getValidAccessToken();
      // If we had a session but refresh failed (returned null), log out
      final hasRefreshToken =
          (await AccessTokenService.getRequestToken()) != null;
      if (hasRefreshToken && token == null) {
        logout();
      }
    } catch (e) {
      debugPrint("Token check on resume failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: AuthGate.routeName,
      routes: {
        CreateAccountScreen.routeName: (context) => CreateAccountScreen(),
        LoginScreen.routeName: (context) => LoginScreen(),
        HomeScreen.routeName: (context) => HomeScreen(),
        WelcomeScreen.routeName: (context) => WelcomeScreen(),
        AuthGate.routeName: (context) => AuthGate(),
        ReviewResponsesScreen.routeName: (context) =>
            ReviewResponsesScreen(token: '', sessionId: ''),
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
  bool _hasConnectionError = false;
  bool _isChecking = true;
  bool _showSkeleton = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performAuthCheck();
    });
  }

  Future<void> _performAuthCheck() async {
    // 1. Initial quick check for token presence
    final refreshToken = await AccessTokenService.getRequestToken();

    if (refreshToken == null || refreshToken.isEmpty) {
      _goTo(const WelcomeScreen());
      return;
    }

    // 2. Token exists, so we show the skeleton while verifying with server
    setState(() {
      _isChecking = true;
      _showSkeleton = true;
      _hasConnectionError = false;
    });

    try {
      // 3. Use TokenManager to ensure we have a valid token (startup check)
      final token = await TokenManager.getValidAccessToken();

      if (token != null) {
        // 4. Navigate immediately to HomeScreen.
        _goTo(const HomeScreen());
      } else {
        // Refresh failed and we have no valid token
        await AccessTokenService.clear();
        _goTo(const WelcomeScreen());
      }
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains("socketexception") ||
          errorStr.contains("httpapi") ||
          errorStr.contains("connection") ||
          errorStr.contains("timeout")) {
        setState(() {
          _isChecking = false;
          _hasConnectionError = true;
        });
      } else {
        await AccessTokenService.clear();
        _goTo(const WelcomeScreen());
      }
    }
  }

  void _goTo(Widget screen) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // If we're checking but don't have a token yet, show a blank scaffold
    // to avoid flashing the skeleton to first-time users.
    if (_isChecking && !_showSkeleton) {
      return const Scaffold();
    }

    return Scaffold(
      appBar: _showSkeleton
          ? AppBar(
              automaticallyImplyLeading: false,
              leading: Padding(
                padding: const EdgeInsets.only(left: AppLayout.space16),
                child: Image.asset("assets/kuvaka_logo.png"),
              ),
              // Placeholder actions to match HomeScreen layout exactly
              actions: [
                IconButton(
                  onPressed: null,
                  icon: Icon(LucideIcons.logOut, color: Colors.transparent),
                ),
              ],
            )
          : null,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isChecking
            ? const HomeSkeleton()
            : _hasConnectionError
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppLayout.space32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppLayout.space20),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error.withAlpha(20),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.wifi_off_rounded,
                          size: AppLayout.iconExtraLarge + 16,
                          color: theme.colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: AppLayout.space24),
                      Text(
                        "Connection Issue",
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppLayout.space8),
                      Text(
                        "We couldn't reach our clinical servers. Please check your internet connection and try again.",
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                      const SizedBox(height: AppLayout.space32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _performAuthCheck,
                          child: const Text("Try Again"),
                        ),
                      ),
                      const SizedBox(height: AppLayout.space12),
                      TextButton(
                        onPressed: () async {
                          await AccessTokenService.clear();
                          _goTo(const WelcomeScreen());
                        },
                        child: const Text("Sign Out"),
                      ),
                    ],
                  ),
                ),
              )
            : const SizedBox(),
      ),
    );
  }
}
