import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../screens/pin_screen.dart';
import '../widgets/reminder_tile.dart';

class CaregiverScreen extends StatefulWidget {
  const CaregiverScreen({super.key});

  @override
  State<CaregiverScreen> createState() => _CaregiverScreenState();
}

class _CaregiverScreenState extends State<CaregiverScreen> {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  final TextEditingController _nameController = TextEditingController();
  final List<TextEditingController> _familyNameControllers =
  List.generate(4, (_) => TextEditingController());

  String _patientName = '';
  List<String> _familyNames = ['', '', '', ''];
  List<String> _familyFilenames = ['', '', '', ''];
  int _recordingIndex = -1;
  int _playingIndex = -1;

  List<bool> _reminderEnabled = List.filled(8, true);
  List<int> _reminderHours = List.filled(8, 8);
  List<int> _reminderMinutes = List.filled(8, 0);

  bool _hasPin = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
    _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() => _playingIndex = -1);
    });
  }

  Future<void> _loadAll() async {
    final name = await StorageService.getPatientName();
    final names = await StorageService.getFamilyNames();
    final rawPaths = await StorageService.getFamilyPaths();
    final filenames = rawPaths.map(_toFilename).toList();
    final hasPin = await StorageService.hasCaregiverPin();

    final enabled = <bool>[];
    final hours = <int>[];
    final minutes = <int>[];

    for (final key in StorageService.reminderKeys) {
      enabled.add(await StorageService.getReminderEnabled(key));
      hours.add(await StorageService.getReminderHour(key));
      minutes.add(await StorageService.getReminderMinute(key));
    }

    if (!mounted) return;
    setState(() {
      _patientName = name;
      _nameController.text = name;
      _familyNames = names;
      _familyFilenames = filenames;
      _reminderEnabled = enabled;
      _reminderHours = hours;
      _reminderMinutes = minutes;
      _hasPin = hasPin;
      for (int i = 0; i < 4; i++) {
        _familyNameControllers[i].text = names[i];
      }
    });
  }

  String _toFilename(String stored) {
    if (stored.isEmpty) return '';
    return stored.contains('/') ? stored.split('/').last : stored;
  }

  Future<void> _saveAll() async {
    await StorageService.savePatientName(_nameController.text.trim());
    final names = _familyNameControllers.map((c) => c.text.trim()).toList();
    await StorageService.saveFamilyNames(names);
    await StorageService.saveFamilyPaths(_familyFilenames);

    for (int i = 0; i < StorageService.reminderKeys.length; i++) {
      final key = StorageService.reminderKeys[i];
      await StorageService.saveReminderEnabled(key, _reminderEnabled[i]);
      await StorageService.saveReminderTime(key, _reminderHours[i], _reminderMinutes[i]);
    }

    await NotificationService.scheduleAll();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved')),
    );
  }

  Future<void> _setupPin() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PinScreen(mode: PinMode.setup)),
    );
    if (result == true && mounted) {
      setState(() => _hasPin = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN set successfully')),
      );
    }
  }

  Future<void> _removePin() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove PIN?'),
        content: const Text('The caregiver settings will be accessible without a PIN.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await StorageService.saveCaregiverPin('');
      if (!mounted) return;
      setState(() => _hasPin = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN removed')));
    }
  }

  Future<void> _toggleRecording(int index) async {
    HapticFeedback.mediumImpact();
    if (_playingIndex != -1) {
      await _player.stop();
      setState(() => _playingIndex = -1);
    }

    if (_recordingIndex == index) {
      await _recorder.stop();
      setState(() => _recordingIndex = -1);
    } else {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) return;
      if (_recordingIndex != -1) await _recorder.stop();

      final dir = await getApplicationDocumentsDirectory();
      final filename = 'family_message_$index.m4a';
      final fullPath = '${dir.path}/$filename';

      await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: fullPath);
      setState(() { _familyFilenames[index] = filename; _recordingIndex = index; });
    }
  }

  Future<void> _togglePreview(int index) async {
    HapticFeedback.lightImpact();
    final filename = _familyFilenames[index];
    if (filename.isEmpty) return;

    if (_recordingIndex != -1) {
      await _recorder.stop();
      setState(() => _recordingIndex = -1);
    }

    await _player.stop();

    if (_playingIndex == index) {
      setState(() => _playingIndex = -1);
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    final fullPath = '${dir.path}/$filename';

    await _player.play(DeviceFileSource(fullPath));
    setState(() => _playingIndex = index);
  }

  Future<void> _pickTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _reminderHours[index], minute: _reminderMinutes[index]),
    );
    if (picked != null) {
      setState(() { _reminderHours[index] = picked.hour; _reminderMinutes[index] = picked.minute; });
    }
  }

  @override
  void dispose() {
    _recorder.dispose();
    _player.dispose();
    _nameController.dispose();
    for (final c in _familyNameControllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C6FAC),
        foregroundColor: Colors.white,
        title: const Text('Caregiver Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.save), onPressed: _saveAll, tooltip: 'Save')],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('Patient Name'),
          const SizedBox(height: 8),
          _inputField(controller: _nameController, hint: 'Enter patient name'),
          const SizedBox(height: 24),
          _sectionTitle('Family Messages'),
          const SizedBox(height: 8),
          ...List.generate(4, (i) => _familyMessageRow(i)),
          const SizedBox(height: 24),
          _sectionTitle('Daily Reminders'),
          const SizedBox(height: 8),
          ...List.generate(StorageService.reminderKeys.length, (i) {
            final key = StorageService.reminderKeys[i];
            final label = StorageService.reminderLabels[key] ?? key;
            return ReminderTile(
              label: label,
              enabled: _reminderEnabled[i],
              hour: _reminderHours[i],
              minute: _reminderMinutes[i],
              onToggle: (val) => setState(() => _reminderEnabled[i] = val),
              onEditTime: () => _pickTime(i),
            );
          }),
          const SizedBox(height: 24),
          _sectionTitle('Security'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 6, offset: const Offset(0, 3))],
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_outline, color: Color(0xFF2C6FAC), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Caregiver PIN', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF3A3A3A))),
                      Text(
                        _hasPin ? 'PIN is set — settings are locked' : 'No PIN — anyone can open settings',
                        style: TextStyle(fontSize: 14, color: _hasPin ? Colors.green[700] : Colors.orange[700]),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _hasPin ? _removePin : _setupPin,
                  child: Text(
                    _hasPin ? 'Remove' : 'Set PIN',
                    style: TextStyle(color: _hasPin ? Colors.red : const Color(0xFF2C6FAC), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: FilledButton.icon(
              onPressed: _saveAll,
              icon: const Icon(Icons.save, size: 26),
              label: const Text('Save All Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2C6FAC),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(text,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF3A3A3A)));

  Widget _inputField({required TextEditingController controller, required String hint}) =>
      TextField(
        controller: controller,
        style: const TextStyle(fontSize: 18),
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );

  Widget _familyMessageRow(int index) {
    final isRecording = _recordingIndex == index;
    final isPlaying = _playingIndex == index;
    final hasRecording = _familyFilenames[index].isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Message ${index + 1}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF3A3A3A))),
          const SizedBox(height: 8),
          _inputField(controller: _familyNameControllers[index], hint: 'Name (e.g. Mom, Sarah)'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: () => _toggleRecording(index),
                    icon: Icon(isRecording ? Icons.stop : Icons.mic),
                    label: Text(
                      isRecording ? 'Stop' : hasRecording ? 'Re-record' : 'Record',
                      style: const TextStyle(fontSize: 15),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: isRecording ? const Color(0xFF3A9E8F) : const Color(0xFF2C6FAC),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
              if (hasRecording) ...[
                const SizedBox(width: 10),
                SizedBox(
                  height: 52,
                  width: 52,
                  child: FilledButton(
                    onPressed: () => _togglePreview(index),
                    style: FilledButton.styleFrom(
                      backgroundColor: isPlaying ? const Color(0xFF3A9E8F) : const Color(0xFF5B8FBF),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Icon(isPlaying ? Icons.stop : Icons.play_arrow, size: 26),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}