import 'package:flutter/material.dart';
import '../services/storage_service.dart';

enum PinMode { setup, verify }

class PinScreen extends StatefulWidget {
  final PinMode mode;

  const PinScreen({super.key, required this.mode});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  String _entered = '';
  String? _firstPin;
  bool _confirming = false;
  String _error = '';

  void _onKey(String digit) {
    if (_entered.length >= 4) return;
    setState(() {
      _entered += digit;
      _error = '';
    });

    if (_entered.length == 4) {
      _handleComplete();
    }
  }

  void _onDelete() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  Future<void> _handleComplete() async {
    if (widget.mode == PinMode.verify) {
      final saved = await StorageService.getCaregiverPin();
      if (_entered == saved) {
        if (!mounted) return;
        Navigator.of(context).pop(true);
      } else {
        setState(() { _entered = ''; _error = 'Incorrect PIN. Try again.'; });
      }
      return;
    }

    if (!_confirming) {
      setState(() {
        _firstPin = _entered;
        _entered = '';
        _confirming = true;
      });
    } else {
      if (_entered == _firstPin) {
        await StorageService.saveCaregiverPin(_entered);
        if (!mounted) return;
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _entered = '';
          _firstPin = null;
          _confirming = false;
          _error = 'PINs did not match. Start over.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSetup = widget.mode == PinMode.setup;
    final title = isSetup
        ? (_confirming ? 'Confirm your PIN' : 'Create a Caregiver PIN')
        : 'Enter Caregiver PIN';
    final subtitle = isSetup
        ? (_confirming
        ? 'Enter your PIN again to confirm'
        : 'This PIN protects the caregiver settings')
        : 'Enter your 4-digit PIN to continue';

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C6FAC),
        foregroundColor: Colors.white,
        title: const Text(
          'Caregiver Access',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3A3A3A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 16, color: Color(0xFF666666)),
            ),
            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final filled = i < _entered.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled
                        ? const Color(0xFF2C6FAC)
                        : Colors.transparent,
                    border: Border.all(
                      color: const Color(0xFF2C6FAC),
                      width: 2,
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 16),
            if (_error.isNotEmpty)
              Text(
                _error,
                style: const TextStyle(color: Colors.red, fontSize: 15),
              ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Column(
                children: [
                  for (final row in [
                    ['1', '2', '3'],
                    ['4', '5', '6'],
                    ['7', '8', '9'],
                    ['', '0', '⌫'],
                  ])
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: row.map((key) {
                        if (key.isEmpty) return const SizedBox(width: 72, height: 72);
                        return _KeyButton(
                          label: key,
                          onTap: () =>
                          key == '⌫' ? _onDelete() : _onKey(key),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _KeyButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _KeyButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3A3A3A),
            ),
          ),
        ),
      ),
    );
  }
}