import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../services/speech_service.dart';
import '../widgets/family_button.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final AudioPlayer _player = AudioPlayer();
  final AudioRecorder _recorder = AudioRecorder();

  String _patientName = 'Friend';
  List<String> _familyNames = ['', '', '', ''];

  List<String> _familyPaths = ['', '', '', ''];

  int _playingIndex = -1;
  bool _isRecording = false;
  bool _hasOwnRecording = false;
  String _ownVoicePath = '';

  bool _isTalking = false;
  String _status = '';
  int _titleTapCount = 0;

  static const int _ownVoiceIndex = 4;

  @override
  void initState() {
    super.initState();
    _loadData();
    _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() { _playingIndex = -1; _status = ''; });
    });
  }

  Future<void> _loadData() async {
    final name = await StorageService.getPatientName();
    final names = await StorageService.getFamilyNames();
    final storedFilenames = await StorageService.getFamilyPaths();

    final dir = await getApplicationDocumentsDirectory();
    final paths = storedFilenames.map((stored) {
      if (stored.isEmpty) return '';
      final filename = stored.contains('/') ? stored.split('/').last : stored;
      return '${dir.path}/$filename';
    }).toList();

    final ownPath = '${dir.path}/patient_voice.m4a';
    final ownExists = await File(ownPath).exists();

    if (!mounted) return;
    setState(() {
      _patientName = name;
      _familyNames = names;
      _familyPaths = paths;
      _ownVoicePath = ownPath;
      _hasOwnRecording = ownExists;
    });
  }

  Future<void> _playFamilyMessage(int index) async {
    if (_isTalking) return;

    final path = _familyPaths[index];
    if (path.isEmpty) {
      setState(() => _status = 'No message recorded yet');
      return;
    }

    await _player.stop();

    if (_playingIndex == index) {
      setState(() { _playingIndex = -1; _status = ''; });
      return;
    }

    await _player.play(DeviceFileSource(path));
    setState(() {
      _playingIndex = index;
      _status = 'Playing message from ${_familyNames[index]}';
    });
  }

  Future<void> _playOwnVoice() async {
    if (!_hasOwnRecording) return;
    await _player.stop();

    if (_playingIndex == _ownVoiceIndex) {
      setState(() { _playingIndex = -1; _status = ''; });
      return;
    }

    await _player.play(DeviceFileSource(_ownVoicePath));
    setState(() {
      _playingIndex = _ownVoiceIndex;
      _status = 'Playing your voice...';
    });
  }

  Future<void> _talkToMe() async {
    if (_isTalking) {
      await TtsService.stop();
      await SpeechService.stop();
      setState(() { _isTalking = false; _status = ''; });
      return;
    }

    await _player.stop();
    setState(() { _playingIndex = -1; _isTalking = true; _status = 'Speaking...'; });

    try {
      final prompt = await TtsService.nextPrompt();
      await TtsService.speakAndWait(prompt);
      if (!_isTalking || !mounted) return;

      setState(() => _status = 'I\'m listening... 🎙');
      final heard = await SpeechService.listen(duration: const Duration(seconds: 12));
      if (!_isTalking || !mounted) return;

      if (heard.trim().isNotEmpty) {
        setState(() => _status = '"${heard.trim()}"');
        await Future.delayed(const Duration(seconds: 2));
        if (!_isTalking || !mounted) return;
      }

      setState(() => _status = 'Speaking...');
      final affirmation = await TtsService.nextAffirmation();
      await TtsService.speakAndWait(affirmation);
    } finally {
      if (mounted) setState(() { _isTalking = false; _status = ''; });
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _recorder.stop();
      final saved = path != null && await File(path).exists();
      setState(() {
        _isRecording = false;
        _hasOwnRecording = saved;
        if (saved) _ownVoicePath = path!;
        _status = saved ? 'Recording saved — tap Play My Voice to hear it' : 'Nothing recorded';
      });
    } else {
      await _player.stop();
      setState(() { _playingIndex = -1; });

      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        setState(() => _status = 'Microphone permission needed');
        return;
      }

      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/patient_voice.m4a';

      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );

      setState(() { _isRecording = true; _status = 'Recording your voice...'; });
    }
  }

  void _onTitleTap() {
    _titleTapCount++;
    if (_titleTapCount >= 3) {
      _titleTapCount = 0;
      Navigator.pushNamed(context, '/caregiver').then((_) => _loadData());
    }
  }

  @override
  void dispose() {
    _player.dispose();
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPlayingOwnVoice = _playingIndex == _ownVoiceIndex;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _onTitleTap,
              child: Text(
                'Hello, $_patientName',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3A3A3A),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (_status.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Color(0xFF2C6FAC)),
                ),
              ),
            const SizedBox(height: 32),

            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: List.generate(4, (i) {
                  final name = _familyNames[i];
                  return Opacity(
                    opacity: _isTalking ? 0.4 : 1.0,
                    child: IgnorePointer(
                      ignoring: _isTalking,
                      child: FamilyButton(
                        name: name.isEmpty ? 'Add Message' : name,
                        isPlaying: _playingIndex == i,
                        onPlay: () => _playFamilyMessage(i),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),

            _ActionButton(
              onPressed: _talkToMe,
              icon: _isTalking ? Icons.cancel_outlined : Icons.chat_bubble_outline,
              label: _isTalking ? 'Stop Talking' : 'Talk to Me',
              color: _isTalking ? const Color(0xFF3A9E8F) : const Color(0xFF2C6FAC),
            ),
            const SizedBox(height: 12),

            _ActionButton(
              onPressed: _toggleRecording,
              icon: _isRecording ? Icons.stop_circle : Icons.mic,
              label: _isRecording
                  ? 'Stop Recording'
                  : _hasOwnRecording
                  ? 'Re-record My Voice'
                  : 'Record My Voice',
              color: _isRecording ? const Color(0xFF3A9E8F) : const Color(0xFF2C6FAC),
            ),
            const SizedBox(height: 12),

            if (_hasOwnRecording)
              _ActionButton(
                onPressed: _playOwnVoice,
                icon: isPlayingOwnVoice ? Icons.stop_circle : Icons.volume_up,
                label: isPlayingOwnVoice ? 'Stop' : 'Play My Voice',
                color: isPlayingOwnVoice ? const Color(0xFF3A9E8F) : const Color(0xFF5B8FBF),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color color;

  const _ActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 64,
        child: FilledButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 28),
          label: Text(
            label,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}