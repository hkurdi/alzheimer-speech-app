import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final FlutterTts _tts = FlutterTts();
  static bool _initialized = false;

  static const List<String> _prompts = [
    'What is your favorite meal?',
    'Tell me about someone you love.',
    'What is a place that makes you happy?',
    'What is your favorite season and why?',
    'Tell me about a happy memory.',
    'What song always makes you smile?',
    'What did you enjoy doing when you were young?',
    'Tell me about your hometown.',
  ];

  static const List<String> _affirmations = [
    'You are loved and you are safe.',
    'You are doing a wonderful job today.',
    'The people who love you are thinking of you.',
    'You are strong and you are not alone.',
    'Today is a good day. You are cared for.',
    'You matter to the people around you.',
    'You are surrounded by love.',
  ];

  static int _promptIndex = 0;
  static int _affirmationIndex = 0;
  static bool _nextIsPrompt = true;

  static Future<void> init() async {
    if (_initialized) return;
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.42); // slightly slower for clarity
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _initialized = true;
  }

  static Future<void> speak(String text) async {
    await init();
    await _tts.stop();
    await _tts.speak(text);
  }

  static Future<void> stop() async {
    await _tts.stop();
  }

  static Future<void> talkToMe() async {
    await init();
    await _tts.stop();

    String text;
    if (_nextIsPrompt) {
      text = _prompts[_promptIndex % _prompts.length];
      _promptIndex++;
    } else {
      text = _affirmations[_affirmationIndex % _affirmations.length];
      _affirmationIndex++;
    }
    _nextIsPrompt = !_nextIsPrompt;

    await _tts.speak(text);
  }

  static Future<void> speakReminder(String reminderKey) async {
    await init();
    await _tts.stop();
    final label = _reminderMessages[reminderKey] ??
        'You have a reminder.';
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