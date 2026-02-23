import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Gradient gradient;
  final bool isActive;
  final Animation<double>? pulseAnim;

  const PrimaryButton({
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
