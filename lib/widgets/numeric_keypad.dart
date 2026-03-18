// lib/widgets/numeric_keypad.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/converter_provider.dart';

// ── Layout of the numeric keypad ────────────────────────────────
// Row 0:  [ Clear ]  [ ⌫ Backspace ]   ← 2-col utility row
// Row 1:    7    8    9
// Row 2:    4    5    6
// Row 3:    1    2    3
// Row 4:   00    0    .
//
// All rows are Expanded so they fill the exact available height — zero overflow.

class NumericKeypad extends StatelessWidget {
  const NumericKeypad({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ConverterProvider>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      child: Column(
        children: [
          // ── Row 0: Clear | Backspace ──────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: _KeyButton(
                      label: 'C',
                      type: _KeyType.clear,
                      onTap: () => provider.onKey('C'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _KeyButton(
                      label: '⌫',
                      type: _KeyType.backspace,
                      onTap: () => provider.onKey('⌫'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Row 1: 7 8 9 ─────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _NumRow(
                  keys: const ['7', '8', '9'],
                  onTap: provider.onKey),
            ),
          ),

          // ── Row 2: 4 5 6 ─────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _NumRow(
                  keys: const ['4', '5', '6'],
                  onTap: provider.onKey),
            ),
          ),

          // ── Row 3: 1 2 3 ─────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _NumRow(
                  keys: const ['1', '2', '3'],
                  onTap: provider.onKey),
            ),
          ),

          // ── Row 4: 00  0  . ──────────────────────────────────────────
          Expanded(
            child: _NumRow(
                keys: const ['00', '0', '.'],
                onTap: provider.onKey),
          ),
        ],
      ),
    );
  }
}

// ── A single row of 3 equal-width buttons ────────────────────────────────────
class _NumRow extends StatelessWidget {
  final List<String> keys;
  final void Function(String) onTap;

  const _NumRow({required this.keys, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < keys.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _KeyButton(
              label: keys[i],
              type: _KeyType.digit,
              onTap: () => onTap(keys[i]),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Key types ────────────────────────────────────────────────────────────────
enum _KeyType { digit, clear, backspace }

// ── Individual key button ─────────────────────────────────────────────────────
class _KeyButton extends StatefulWidget {
  final String label;
  final _KeyType type;
  final VoidCallback onTap;

  const _KeyButton({
    required this.label,
    required this.type,
    required this.onTap,
  });

  @override
  State<_KeyButton> createState() => _KeyButtonState();
}

class _KeyButtonState extends State<_KeyButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 70),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _down(_) => _ctrl.forward();
  void _up(_) {
    _ctrl.reverse();
    widget.onTap();
  }
  void _cancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    // Colour scheme per key type
    final (Color bg, Color fg, bool glow) = switch (widget.type) {
      _KeyType.backspace => (
          const Color(0xFFFF6B35),
          Colors.white,
          true,
        ),
      _KeyType.clear => (
          const Color(0xFF2A2A40),
          const Color(0xFFFF6B35),
          false,
        ),
      _KeyType.digit => (
          const Color(0xFF1C1C30),
          Colors.white.withOpacity(0.90),
          false,
        ),
    };

    return GestureDetector(
      onTapDown: _down,
      onTapUp: _up,
      onTapCancel: _cancel,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          // No fixed height — expands to fill the Expanded parent
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.22),
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
              if (glow)
                BoxShadow(
                  color: const Color(0xFFFF6B35).withOpacity(0.28),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
            ],
          ),
          alignment: Alignment.center,
          child: _buildLabel(fg),
        ),
      ),
    );
  }

  Widget _buildLabel(Color fg) {
    if (widget.label == '⌫') {
      return Icon(Icons.backspace_outlined, color: fg, size: 20);
    }
    if (widget.label == 'C') {
      return Text(
        'Clear',
        style: GoogleFonts.dmSans(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      );
    }
    // digits, 00, .
    return Text(
      widget.label,
      style: GoogleFonts.dmMono(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: fg,
      ),
    );
  }
}
