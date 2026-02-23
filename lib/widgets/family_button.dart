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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPlay,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          color: isEmpty
              ? const Color(0xFFDDE8F5)
              : isPlaying
              ? const Color(0xFF3A9E8F)
              : const Color(0xFF2C6FAC),
          borderRadius: BorderRadius.circular(20),
          border: isEmpty
              ? Border.all(color: const Color(0xFF2C6FAC), width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isEmpty ? 0.05 : 0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isEmpty
                  ? Icons.add_circle_outline
                  : isPlaying
                  ? Icons.volume_up
                  : Icons.play_circle_fill,
              color: isEmpty ? const Color(0xFF2C6FAC) : Colors.white,
              size: 48,
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                name.length > 12 ? '${name.substring(0, 12)}…' : name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isEmpty ? const Color(0xFF2C6FAC) : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}