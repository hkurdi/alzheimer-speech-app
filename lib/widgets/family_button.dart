import 'package:flutter/material.dart';

class FamilyButton extends StatelessWidget {
  final String name;
  final bool isPlaying;
  final bool isEmpty;
  final VoidCallback onPlay;

  const FamilyButton({
    super.key,
    required this.name,
    required this.isPlaying,
    required this.onPlay,
    this.isEmpty = false,
  });

  static const _avatarColors = [
    Color(0xFFE07B54),
    Color(0xFF5B7FA6),
    Color(0xFF5AA68A),
    Color(0xFF9B6EA8),
  ];

  Color _avatarColor(String name) {
    if (name.isEmpty) return const Color(0xFFCDD5E0);
    return _avatarColors[name.codeUnits.first % _avatarColors.length];
  }

  String _initial(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '+';
    return trimmed[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final color = isEmpty ? const Color(0xFFCDD5E0) : _avatarColor(name);
    final displayName = name.length > 10 ? '${name.substring(0, 10)}…' : name;

    return GestureDetector(
      onTap: onPlay,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: isEmpty
              ? Border.all(color: const Color(0xFFCDD5E0), width: 1.5)
              : isPlaying
              ? Border.all(color: color, width: 2)
              : null,
          boxShadow: isEmpty
              ? []
              : [
            BoxShadow(
              color: isPlaying
                  ? color.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.07),
              blurRadius: isPlaying ? 16 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: isEmpty
                    ? const Color(0xFFF0F4F8)
                    : isPlaying
                    ? color
                    : color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isPlaying
                    ? const _WaveIcon()
                    : Text(
                  isEmpty ? '+' : _initial(name),
                  style: TextStyle(
                    fontSize: isEmpty ? 28 : 26,
                    fontWeight: FontWeight.w700,
                    color: isEmpty
                        ? const Color(0xFFADB8C5)
                        : isPlaying
                        ? Colors.white
                        : color,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isEmpty ? 'Add Message' : displayName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isEmpty ? const Color(0xFFADB8C5) : const Color(0xFF1A2B3C),
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isEmpty ? 'Tap to set up' : isPlaying ? 'Playing…' : 'Tap to play',
              style: TextStyle(
                fontSize: 11,
                color: isEmpty
                    ? const Color(0xFFCDD5E0)
                    : isPlaying
                    ? color
                    : const Color(0xFF9AACBE),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaveIcon extends StatefulWidget {
  const _WaveIcon();

  @override
  State<_WaveIcon> createState() => _WaveIconState();
}

class _WaveIconState extends State<_WaveIcon> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(3, (i) {
            final delay = i * 0.33;
            final t = (_ctrl.value + delay) % 1.0;
            final h = 8.0 + 14.0 * (0.5 + 0.5 * (t * 2 * 3.14159).toDouble()).abs();
            return Container(
              width: 4,
              height: h.clamp(8, 22),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}