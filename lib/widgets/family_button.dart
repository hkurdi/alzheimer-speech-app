import 'package:flutter/material.dart';

class FamilyButton extends StatelessWidget {
  final String name;
  final bool isPlaying;
  final VoidCallback onPlay;

  const FamilyButton({
    super.key,
    required this.name,
    required this.isPlaying,
    required this.onPlay,
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
          color: isPlaying ? const Color(0xFF3A9E8F) : const Color(0xFF2C6FAC),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPlaying ? Icons.volume_up : Icons.play_circle_fill,
              color: Colors.white,
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
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
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