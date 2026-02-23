import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
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
  String _status = '';
  int _titleTapCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _playingIndex = -1;
        _status = '';
      });
    });
  }

  Future<void> _loadData() async {
    final name = await StorageService.getPatientName();
    final names = await StorageService.getFamilyNames();
    final paths = await StorageService.getFamilyPaths();
    if (!mounted) return;
    setState(() {
      _patientName = name;
      _familyNames = names;
      _familyPaths = paths;
    });
  }

  Future<void> _playFamilyMessage(int index) async {
    final path = _familyPaths[index];
    if (path.isEmpty) {
      setState(() => _status = 'No message recorded yet');
      return;
    }

    await _player.stop();

    if (_playingIndex == index) {
      setState(() {
        _playingIndex = -1;
        _status = '';
      });
      return;
    }

    await _player.play(DeviceFileSource(path));
    setState(() {
      _playingIndex = index;
      _status = 'Playing message from ${_familyNames[index]}';
    });
  }

  Future<void> _talkToMe() async {
    await _player.stop();
    setState(() {
      _playingIndex = -1;
      _status = 'Speaking...';
    });
    await TtsService.talkToMe();
    setState(() => _status = '');
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _recorder.stop();
      setState(() {
        _isRecording = false;
        _status = path != null ? 'Recording saved' : 'Nothing recorded';
      });
    } else {
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

      setState(() {
        _isRecording = true;
        _status = 'Recording your voice...';
      });
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
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF2C6FAC),
                  ),
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
                  return FamilyButton(
                    name: name.isEmpty ? 'Add Message' : name,
                    isPlaying: _playingIndex == i,
                    onPlay: () => _playFamilyMessage(i),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 64,
                child: FilledButton.icon(
                  onPressed: _talkToMe,
                  icon: const Icon(Icons.chat_bubble_outline, size: 28),
                  label: const Text(
                    'Talk to Me',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2C6FAC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 64,
                child: FilledButton.icon(
                  onPressed: _toggleRecording,
                  icon: Icon(
                    _isRecording ? Icons.stop_circle : Icons.mic,
                    size: 28,
                  ),
                  label: Text(
                    _isRecording ? 'Stop Recording' : 'Record My Voice',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: _isRecording
                        ? const Color(0xFF3A9E8F)
                        : const Color(0xFF2C6FAC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}