import 'dart:async';

import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  static final SpeechToText _stt = SpeechToText();
  static bool _available = false;
  static bool _initialized = false;

  static Future<bool> init() async {
    if (_initialized) return _available;
    _available = await _stt.initialize(
      onError: (error) {},
      onStatus: (status) {},
    );
    _initialized = true;
    return _available;
  }

  static Future<String> listen({
    Duration duration = const Duration(seconds: 12),
  }) async {
    final available = await init();
    if (!available) return '';

    final completer = _SpeechCompleter();

    await _stt.stop();
    await Future.delayed(const Duration(milliseconds: 200));

    await _stt.listen(
      listenFor: duration,
      pauseFor: const Duration(seconds: 4),
      localeId: 'en_US',
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        cancelOnError: true,
      ),
      onResult: (result) {
        if (result.finalResult) {
          completer.complete(result.recognizedWords);
        }
      },
    );

    return await completer.future.timeout(
      duration + const Duration(seconds: 2),
      onTimeout: () {
        _stt.stop();
        return completer.lastWords;
      },
    );
  }

  static Future<void> stop() async {
    if (_stt.isListening) await _stt.stop();
  }

  static bool get isListening => _stt.isListening;
}

class _SpeechCompleter {
  String lastWords = '';
  final _completer = _LazyCompleter<String>();

  void complete(String words) {
    lastWords = words;
    _completer.complete(words);
  }

  Future<String> get future => _completer.future;
}

class _LazyCompleter<T> {
  T? _value;
  final List<_Waiter<T>> _waiters = [];
  bool _completed = false;

  void complete(T value) {
    if (_completed) return;
    _completed = true;
    _value = value;
    for (final w in _waiters) {
      w.complete(value);
    }
    _waiters.clear();
  }

  Future<T> get future {
    if (_completed) return Future.value(_value as T);
    final waiter = _Waiter<T>();
    _waiters.add(waiter);
    return waiter.future;
  }
}

class _Waiter<T> {
  final _c = Completer<T>();
  void complete(T value) => _c.complete(value);
  Future<T> get future => _c.future;
}