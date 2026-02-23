import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TtsService {
  static final FlutterTts _tts = FlutterTts();
  static bool _initialized = false;

  static const String _keyPromptIndex = 'tts_prompt_index';
  static const String _keyAffirmationIndex = 'tts_affirmation_index';

  static const List<String> _prompts = [
    'What is your favorite meal?',
    'Tell me about someone you love.',
    'What is a place that makes you happy?',
    'What is your favorite season and why?',
    'Tell me about a happy memory.',
    'What song always makes you smile?',
    'What did you enjoy doing when you were young?',
    'Tell me about your hometown.',
    'What is something that always makes you laugh?',
    'Tell me about a trip you have taken.',
    'Who is someone that always makes you feel better?',
    'What is your favorite thing to do on a quiet day?',
  ];

  static const List<String> _affirmations = [
    'You are loved and you are safe.',
    'You are doing a wonderful job today.',
    'The people who love you are thinking of you.',
    'You are strong and you are not alone.',
    'Today is a good day. You are cared for.',
    'You matter to the people around you.',
    'You are surrounded by love.',
    'Thank you for sharing that with me.',
    'That is a beautiful thing to think about.',
    'You have such a warm heart.',
  ];

  static Future<void> init() async {
    if (_initialized) return;
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.42);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _initialized = true;
  }

  static Future<void> speak(String text) async {
    await init();
    await _tts.stop();
    await _tts.speak(text);
  }

  static Future<void> speakAndWait(String text) async {
    await init();
    await _tts.stop();

    final completer = Completer<void>();

    _tts.setCompletionHandler(() {
      if (!completer.isCompleted) completer.complete();
    });

    _tts.setErrorHandler((msg) {
      if (!completer.isCompleted) completer.complete();
    });

    await _tts.speak(text);
    await completer.future;
  }

  static Future<void> stop() async {
    await _tts.stop();
  }

  static Future<String> nextPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_keyPromptIndex) ?? 0;
    final prompt = _prompts[index % _prompts.length];
    await prefs.setInt(_keyPromptIndex, index + 1);
    return prompt;
  }

  static Future<String> nextAffirmation() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_keyAffirmationIndex) ?? 0;
    final affirmation = _affirmations[index % _affirmations.length];
    await prefs.setInt(_keyAffirmationIndex, index + 1);
    return affirmation;
  }

  static Future<void> speakReminder(String reminderKey) async {
    await init();
    await _tts.stop();
    final label = _reminderMessages[reminderKey] ?? 'You have a reminder.';
    await _tts.speak(label);
  }

  static const Map<String, String> _reminderMessages = {
    'medication':  'It is time to take your medication.',
    'breakfast':   'Good morning. It is time for breakfast.',
    'lunch':       'It is time for lunch.',
    'dinner':      'It is time for dinner.',
    'hydration':   'Please drink a glass of water.',
    'exercise':    'It is time for a short walk.',
    'family_call': 'It is a good time to call your family.',
    'bedtime':     'It is time to get ready for bed. Good night.',
  };
}