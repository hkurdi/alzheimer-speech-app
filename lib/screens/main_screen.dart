import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../services/speech_service.dart';
import '../services/notification_service.dart';
import '../screens/pin_screen.dart';
import '../widgets/family_button.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
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

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  static const int _ownVoiceIndex = 4;

  static const _navy = Color(0xFF1E3A5F);
  static const _coral = Color(0xFFE07B54);
  static const _warmWhite = Color(0xFFFFFFFF);
  static const _teal = Color(0xFF3A9E8F);
  static const _textPrimary = Color(0xFF1A2B3C);
  static const _textSecondary = Color(0xFF7A8A9A);

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    _loadData();
    _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() { _playingIndex = -1; _status = ''; });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.flushPendingPayload();
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

    _fadeController.forward();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  IconData get _greetingIcon {
    final hour = DateTime.now().hour;
    if (hour < 12) return Icons.wb_sunny_rounded;
    if (hour < 17) return Icons.wb_cloudy_rounded;
    return Icons.nights_stay_rounded;
  }

  Future<void> _playFamilyMessage(int index) async {
    if (_isTalking) return;
    HapticFeedback.mediumImpact();

    final path = _familyPaths[index];
    final name = _familyNames[index];

    if (path.isEmpty || name.isEmpty) {
      _showEmptyMessageSheet();
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
      _status = 'Playing message from $name ♪';
    });
  }

  void _showEmptyMessageSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: _warmWhite,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _navy.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mic_none_rounded, size: 36, color: _navy),
            ),
            const SizedBox(height: 20),
            const Text(
              'No message yet',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _textPrimary),
            ),
            const SizedBox(height: 10),
            const Text(
              'Ask a family member to open Caregiver Settings and record a personal voice message for you.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: _textSecondary, height: 1.6),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: _navy,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Got it', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _playOwnVoice() async {
    if (!_hasOwnRecording) return;
    HapticFeedback.mediumImpact();
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
    HapticFeedback.mediumImpact();
    if (_isTalking) {
      await TtsService.stop();
      await SpeechService.stop();
      setState(() { _isTalking = false; _status = ''; });
      _pulseController.stop();
      return;
    }

    await _player.stop();
    _pulseController.repeat(reverse: true);
    setState(() { _playingIndex = -1; _isTalking = true; _status = 'Speaking to you...'; });

    try {
      final prompt = await TtsService.nextPrompt();
      await TtsService.speakAndWait(prompt);
      if (!_isTalking || !mounted) return;

      setState(() => _status = 'Listening... 🎙');
      final heard = await SpeechService.listen(duration: const Duration(seconds: 12));
      if (!_isTalking || !mounted) return;

      if (heard.trim().isNotEmpty) {
        setState(() => _status = '"${heard.trim()}"');
        await Future.delayed(const Duration(seconds: 2));
        if (!_isTalking || !mounted) return;
      }

      setState(() => _status = 'Speaking to you...');
      final affirmation = await TtsService.nextAffirmation();
      await TtsService.speakAndWait(affirmation);
    } finally {
      if (mounted) {
        _pulseController.repeat(reverse: true);
        setState(() { _isTalking = false; _status = ''; });
      }
    }
  }

  Future<void> _toggleRecording() async {
    HapticFeedback.mediumImpact();
    if (_isRecording) {
      final path = await _recorder.stop();
      final saved = path != null && await File(path).exists();
      setState(() {
        _isRecording = false;
        _hasOwnRecording = saved;
        if (saved) _ownVoicePath = path;
        _status = saved ? 'Voice saved ✓' : '';
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
      await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
      setState(() { _isRecording = true; _status = 'Recording... 🔴'; });
    }
  }

  Future<void> _onTitleTap() async {
    _titleTapCount++;
    if (_titleTapCount < 3) return;
    _titleTapCount = 0;
    HapticFeedback.heavyImpact();

    final hasPin = await StorageService.hasCaregiverPin();
    if (!mounted) return;

    bool granted = false;
    if (hasPin) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PinScreen(mode: PinMode.verify)),
      );
      granted = result == true;
    } else {
      granted = true;
    }

    if (granted && mounted) {
      await Navigator.pushNamed(context, '/caregiver');
      _loadData();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    _player.dispose();
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPlayingOwnVoice = _playingIndex == _ownVoiceIndex;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFDF9F5), Color(0xFFF0E8DF), Color(0xFFE8EEF8)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
                  child: GestureDetector(
                    onTap: _onTitleTap,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(_greetingIcon, color: _coral, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              _greeting,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: _coral,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _patientName,
                          style: const TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            color: _navy,
                            letterSpacing: -0.5,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: _status.isNotEmpty ? 44 : 0,
                  margin: const EdgeInsets.fromLTRB(28, 12, 28, 0),
                  child: _status.isNotEmpty
                      ? AnimatedOpacity(
                    opacity: _status.isNotEmpty ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: _isTalking
                            ? _teal.withValues(alpha: 0.12)
                            : _navy.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: _isTalking
                              ? _teal.withValues(alpha: 0.3)
                              : _navy.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isTalking)
                            ScaleTransition(
                              scale: _pulseAnim,
                              child: Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(right: 10),
                                decoration: const BoxDecoration(
                                  color: _teal,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          Flexible(
                            child: Text(
                              _status,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _isTalking ? _teal : _textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                      : const SizedBox(),
                ),

                const SizedBox(height: 24),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Row(
                    children: [
                      Container(width: 4, height: 16, decoration: BoxDecoration(color: _coral, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 10),
                      const Text(
                        'Family Messages',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textSecondary, letterSpacing: 1.2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      physics: const NeverScrollableScrollPhysics(),
                      children: List.generate(4, (i) {
                        final name = _familyNames[i];
                        final isEmpty = name.isEmpty || _familyPaths[i].isEmpty;
                        return Opacity(
                          opacity: _isTalking ? 0.35 : 1.0,
                          child: IgnorePointer(
                            ignoring: _isTalking,
                            child: FamilyButton(
                              name: isEmpty ? 'Add Message' : name,
                              isPlaying: _playingIndex == i,
                              isEmpty: isEmpty,
                              onPlay: () => _playFamilyMessage(i),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),

                Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  decoration: BoxDecoration(
                    color: _warmWhite.withValues(alpha: 0.7),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    boxShadow: [
                      BoxShadow(
                        color: _navy.withValues(alpha: 0.06),
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _PrimaryButton(
                        onPressed: _talkToMe,
                        icon: _isTalking ? Icons.cancel_rounded : Icons.chat_bubble_rounded,
                        label: _isTalking ? 'Stop' : 'Talk to Me',
                        gradient: _isTalking
                            ? const LinearGradient(colors: [Color(0xFF3A9E8F), Color(0xFF2E7D6E)])
                            : const LinearGradient(colors: [Color(0xFF2C5282), Color(0xFF1E3A5F)]),
                        isActive: _isTalking,
                        pulseAnim: _isTalking ? _pulseAnim : null,
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: _SecondaryButton(
                              onPressed: _toggleRecording,
                              icon: _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                              label: _isRecording ? 'Stop' : _hasOwnRecording ? 'Re-record' : 'Record Voice',
                              color: _isRecording ? _teal : _navy,
                            ),
                          ),
                          if (_hasOwnRecording) ...[
                            const SizedBox(width: 10),
                            Expanded(
                              child: _SecondaryButton(
                                onPressed: _playOwnVoice,
                                icon: isPlayingOwnVoice ? Icons.stop_rounded : Icons.volume_up_rounded,
                                label: isPlayingOwnVoice ? 'Stop' : 'My Voice',
                                color: isPlayingOwnVoice ? _teal : const Color(0xFF5B7FA6),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Gradient gradient;
  final bool isActive;
  final Animation<double>? pulseAnim;

  const _PrimaryButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.gradient,
    this.isActive = false,
    this.pulseAnim,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (isActive ? const Color(0xFF3A9E8F) : const Color(0xFF1E3A5F)).withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.2),
            ),
          ],
        ),
      ),
    );

    if (pulseAnim != null) {
      return ScaleTransition(scale: pulseAnim!, child: button);
    }
    return button;
  }
}

class _SecondaryButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color color;

  const _SecondaryButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}