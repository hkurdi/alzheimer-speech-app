import 'package:flutter/material.dart';

class ReminderTile extends StatelessWidget {
  final String label;
  final bool enabled;
  final int hour;
  final int minute;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEditTime;

  const ReminderTile({
    super.key,
    required this.label,
    required this.enabled,
    required this.hour,
    required this.minute,
    required this.onToggle,
    required this.onEditTime,
  });

  String get _timeLabel {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final m = minute.toString().padLeft(2, '0');
    final period = hour < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
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
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: enabled ? const Color(0xFF3A3A3A) : Colors.grey,
          ),
        ),
        subtitle: GestureDetector(
          onTap: enabled ? onEditTime : null,
          child: Row(
            children: [
              Icon(
                Icons.access_time,
                size: 16,
                color: enabled ? const Color(0xFF2C6FAC) : Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                _timeLabel,
                style: TextStyle(
                  fontSize: 16,
                  color: enabled ? const Color(0xFF2C6FAC) : Colors.grey,
                ),
              ),
              const SizedBox(width: 6),
              if (enabled)
                const Text(
                  '(tap to change)',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
            ],
          ),
        ),
        trailing: Switch(
          value: enabled,
          activeThumbColor: const Color(0xFF2C6FAC),
          onChanged: onToggle,
        ),
      ),
    );
  }
}