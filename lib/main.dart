import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/main_screen.dart';
import 'screens/caregiver_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  runApp(const AlzheimerSpeechApp());
}

class AlzheimerSpeechApp extends StatefulWidget {
  const AlzheimerSpeechApp({super.key});

  @override
  State<AlzheimerSpeechApp> createState() => _AlzheimerSpeechAppState();
}

class _AlzheimerSpeechAppState extends State<AlzheimerSpeechApp> {
  String? _initialRoute;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _resolveInitialRoute();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.microphone,
      Permission.notification,
    ].request();
    await NotificationService.scheduleAll();
  }

  Future<void> _resolveInitialRoute() async {
    final done = await StorageService.isOnboardingComplete();
    setState(() => _initialRoute = done ? '/' : '/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    if (_initialRoute == null) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Color(0xFFFAF7F2),
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFF2C6FAC)),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'Alzheimer Speech App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2C6FAC)),
        scaffoldBackgroundColor: const Color(0xFFFAF7F2),
        useMaterial3: true,
      ),
      initialRoute: _initialRoute,
      routes: {
        '/': (context) => const MainScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/caregiver': (context) => const CaregiverScreen(),
      },
    );
  }
}