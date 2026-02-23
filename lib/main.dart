import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/main_screen.dart';
import 'screens/caregiver_screen.dart';
import 'services/notification_service.dart';

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
  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.microphone,
      Permission.notification,
    ].request();
    await NotificationService.scheduleAll();
  }

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
      initialRoute: '/',
      routes: {
        '/': (context) => const MainScreen(),
        '/caregiver': (context) => const CaregiverScreen(),
      },
    );
  }
}