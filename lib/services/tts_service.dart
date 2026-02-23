import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TtsService {
  static final String _apiKey = dotenv.env['ELEVENLABS_KEY'] ?? '';
  static final String _voiceId = dotenv.env['ELEVENLABS_VOICE_ID'] ?? '';

  static final AudioPlayer _audioPlayer = AudioPlayer();

  static const String _keyPromptIndex = 'tts_prompt_index';

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

  static const List<String> _fallbackAffirmations = [
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

  static Future<void> speak(String text) async {
    final url = Uri.parse(
      'https://api.elevenlabs.io/v1/text-to-speech/$_voiceId',
    );

    final response = await http.post(
      url,
      headers: {
        'Accept': 'audio/mpeg',
        'xi-api-key': _apiKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'text': text,
        'model_id': 'eleven_multilingual_v2',
        'voice_settings': {
          'stability': 0.5,
          'similarity_boost': 0.75,
        }
      }),
    );

    if (response.statusCode == 200) {
      await _audioPlayer.setAudioSource(
        AudioSource.uri(
          Uri.dataFromBytes(
            response.bodyBytes,
            mimeType: 'audio/mpeg',
          ),
        ),
      );
      await _audioPlayer.play();
    } else {
      print('ElevenLabs ERROR: ${response.statusCode}');
      print(response.body);
      throw Exception('Failed to generate speech');
    }
  }

  static Future<void> stop() async {
    await _audioPlayer.stop();
  }

  static Future<void> speakAndWait(String text) async {
    await speak(text);

    await _audioPlayer.playerStateStream.firstWhere(
          (state) =>
      state.processingState == ProcessingState.completed ||
          state.processingState == ProcessingState.idle,
    );
  }

  static Future<String> nextPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_keyPromptIndex) ?? 0;
    final prompt = _prompts[index % _prompts.length];
    await prefs.setInt(_keyPromptIndex, index + 1);
    return prompt;
  }

  static String randomFallbackAffirmation() {
    final index =
        DateTime.now().millisecond % _fallbackAffirmations.length;
    return _fallbackAffirmations[index];
  }

  static Future<void> speakReminder(String reminderKey) async {
    final label =
        _reminderMessages[reminderKey] ?? 'You have a reminder.';
    await speak(label);
  }

  static const Map<String, String> _reminderMessages = {
    'medication': 'It is time to take your medication.',
    'breakfast': 'Good morning. It is time for breakfast.',
    'lunch': 'It is time for lunch.',
    'dinner': 'It is time for dinner.',
    'hydration': 'Please drink a glass of water.',
    'exercise': 'It is time for a short walk.',
    'family_call': 'It is a good time to call your family.',
    'bedtime': 'It is time to get ready for bed. Good night.',
  };
}