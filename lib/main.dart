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

class AlzheimerSpeechApp extends StatelessWidget {
  const AlzheimerSpeechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alzheimer Speech App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2C6FAC)),
        scaffoldBackgroundColor: const Color(0xFFFAF7F2),
        useMaterial3: true,
      ),
      routes: {
        '/': (context) => const _AppEntry(),
        '/main': (context) => const MainScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/caregiver': (context) => const CaregiverScreen(),
      },
    );
  }
}

class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await [
      Permission.microphone,
      Permission.notification,
    ].request();
    await NotificationService.scheduleAll();

    if (!mounted) return;
    final done = await StorageService.isOnboardingComplete();
    if (!mounted) return;

    Navigator.pushReplacementNamed(
      context,
      done ? '/main' : '/onboarding',
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFFAF7F2),
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFF2C6FAC)),
      ),
    );
  }
}