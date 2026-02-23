import 'dart:convert';
import 'package:http/http.dart' as http;

class AiService {
  static const _apiKey = '';

  static const _endpoint = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-haiku-4-5-20251001';

  static const _systemPrompt =
      'You are a warm, caring companion for an elderly person with Alzheimer\'s disease. '
      'When they share something with you, respond with genuine warmth and reflect back what they said in a meaningful way. '
      'Celebrate their memories, validate their feelings, and make them feel heard and cherished. '
      'Keep responses to 2–3 short sentences maximum. Use simple, plain language. '
      'NEVER ask follow-up questions. NEVER ask "what about you" or "tell me more". '
      'End every response with a warm, affirming statement — not a question. '
      'If they said nothing or were unclear, respond with gentle encouragement and a fond reflection on life. '
      'Speak as a devoted, patient friend sitting beside them who genuinely cares.';

  static bool get isConfigured => _apiKey.isNotEmpty;

  static Future<String?> respond({
    required String prompt,
    required String userSpeech,
  }) async {
    if (!isConfigured) return null;

    final userMessage = userSpeech.trim().isEmpty
        ? 'You asked the person: "$prompt" — they did not respond. '
        'Give a single warm, gentle encouragement.'
        : 'You asked the person: "$prompt"\n'
        'They said: "$userSpeech"\n'
        'Respond warmly and briefly in 1–2 sentences.';

    try {
      final response = await http
          .post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': 120,
          'system': _systemPrompt,
          'messages': [
            {'role': 'user', 'content': userMessage},
          ],
        }),
      )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final text = (data['content'] as List)
            .where((b) => b['type'] == 'text')
            .map((b) => b['text'] as String)
            .join(' ')
            .trim();
        return text.isNotEmpty ? text : null;
      }
    } catch (_) {}
    return null;
  }
}