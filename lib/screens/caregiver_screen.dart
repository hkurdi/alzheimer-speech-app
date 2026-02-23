import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../widgets/reminder_tile.dart';

class CaregiverScreen extends StatefulWidget {
  const CaregiverScreen({super.key});

  @override
  State<CaregiverScreen> createState() => _CaregiverScreenState();
}

class _CaregiverScreenState extends State<CaregiverScreen> {
  final AudioRecorder _recorder = AudioRecorder();
  final TextEditingController _nameController = TextEditingController();
  final List<TextEditingController> _familyNameControllers =
  List.generate(4, (_) => TextEditingController());

  String _patientName = '';
  List<String> _familyNames = ['', '', '', ''];
  List<String> _familyPaths = ['', '', '', ''];
  int _recordingIndex = -1;

  List<bool> _reminderEnabled = List.filled(8, true);
  List<int> _reminderHours = List.filled(8, 8);
  List<int> _reminderMinutes = List.filled(8, 0);

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final name = await StorageService.getPatientName();
    final names = await StorageService.getFamilyNames();
    final paths = await StorageService.getFamilyPaths();

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
      _familyPaths = paths;
      _reminderEnabled = enabled;
      _reminderHours = hours;
      _reminderMinutes = minutes;
      for (int i = 0; i < 4; i++) {
        _familyNameControllers[i].text = names[i];
      }
    });
  }

  Future<void> _saveAll() async {
    await StorageService.savePatientName(_nameController.text.trim());
    final names = _familyNameControllers.map((c) => c.text.trim()).toList();
    await StorageService.saveFamilyNames(names);
    await StorageService.saveFamilyPaths(_familyPaths);

    for (int i = 0; i < StorageService.reminderKeys.length; i++) {
      final key = StorageService.reminderKeys[i];
      await StorageService.saveReminderEnabled(key, _reminderEnabled[i]);
      await StorageService.saveReminderTime(
          key, _reminderHours[i], _reminderMinutes[i]);
    }

    await NotificationService.scheduleAll();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved')),
    );
  }

  Future<void> _toggleRecording(int index) async {
    if (_recordingIndex == index) {
      final path = await _recorder.stop();
      if (path != null) {
        setState(() {
          _familyPaths[index] = path;
          _recordingIndex = -1;
        });
      }
    } else {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) return;

      if (_recordingIndex != -1) {
        await _recorder.stop();
      }

      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/family_message_$index.m4a';

      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );

      setState(() => _recordingIndex = index);
    }
  }

  Future<void> _pickTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _reminderHours[index],
        minute: _reminderMinutes[index],
      ),
    );
    if (picked != null) {
      setState(() {
        _reminderHours[index] = picked.hour;
        _reminderMinutes[index] = picked.minute;
      });
    }
  }

  @override
  void dispose() {
    _recorder.dispose();
    _nameController.dispose();
    for (final c in _familyNameControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C6FAC),
        foregroundColor: Colors.white,
        title: const Text(
          'Caregiver Settings',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveAll,
            tooltip: 'Save',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('Patient Name'),
          const SizedBox(height: 8),
          _inputField(
            controller: _nameController,
            hint: 'Enter patient name',
          ),
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
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: FilledButton.icon(
              onPressed: _saveAll,
              icon: const Icon(Icons.save, size: 26),
              label: const Text(
                'Save All Settings',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2C6FAC),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF3A3A3A),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 18),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _familyMessageRow(int index) {
    final isRecording = _recordingIndex == index;
    final hasRecording = _familyPaths[index].isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Message ${index + 1}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3A3A3A),
            ),
          ),
          const SizedBox(height: 8),
          _inputField(
            controller: _familyNameControllers[index],
            hint: 'Name (e.g. Mom, Sarah)',
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: () => _toggleRecording(index),
              icon: Icon(isRecording ? Icons.stop : Icons.mic),
              label: Text(
                isRecording
                    ? 'Stop Recording'
                    : hasRecording
                    ? 'Re-record Message'
                    : 'Record Message',
                style: const TextStyle(fontSize: 16),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: isRecording
                    ? const Color(0xFF3A9E8F)
                    : const Color(0xFF2C6FAC),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}