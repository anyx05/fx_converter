// lib/screens/converter_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/converter_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/numeric_keypad.dart';

class ConverterScreen extends StatelessWidget {
  const ConverterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          const _BackgroundGradient(),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 6),
                // ── Status banner ──────────────────────────────────────
                const _StatusBanner(),
                const SizedBox(height: 10),
                // ── Two currency cards ─────────────────────────────────
                const CurrencyCard(cardIndex: 1),
                // Swap icon between the two cards
                const _SwapDivider(),
                const CurrencyCard(cardIndex: 2),
                const SizedBox(height: 8),
                Divider(
                  color: Colors.white.withOpacity(0.08),
                  thickness: 1,
                  indent: 20,
                  endIndent: 20,
                ),
                // ── Keypad fills all remaining space ───────────────────
                const Expanded(child: NumericKeypad()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white54, size: 18),
          onPressed: () {},
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.currency_exchange_rounded,
              color: Color(0xFFFF6B35), size: 18),
          const SizedBox(width: 8),
          Text(
            'FX Convert',
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white38, size: 20),
          onPressed: () {
            final p = context.read<ConverterProvider>();
            p.setActiveCard(p.activeCard);
          },
        ),
      ],
    );
  }
}

// ── Swap divider ─────────────────────────────────────────────────────────────
class _SwapDivider extends StatelessWidget {
  const _SwapDivider();

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ConverterProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: Colors.white.withOpacity(0.07),
              indent: 28,
              endIndent: 12,
              thickness: 1,
            ),
          ),
          GestureDetector(
            onTap: provider.swap,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1E1E32),
                border: Border.all(
                  color: const Color(0xFFFF6B35).withOpacity(0.35),
                  width: 1,
                ),
              ),
              child: const Icon(Icons.swap_vert_rounded,
                  color: Color(0xFFFF6B35), size: 17),
            ),
          ),
          Expanded(
            child: Divider(
              color: Colors.white.withOpacity(0.07),
              indent: 12,
              endIndent: 28,
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Background gradient ──────────────────────────────────────────────────────
class _BackgroundGradient extends StatelessWidget {
  const _BackgroundGradient();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D0D1A),
            Color(0xFF12122A),
            Color(0xFF0A0A18),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -40,
            child: _GlowOrb(
              color: const Color(0xFFFF6B35).withOpacity(0.10),
              size: 200,
            ),
          ),
          Positioned(
            bottom: 180,
            left: -60,
            child: _GlowOrb(
              color: const Color(0xFF6C63FF).withOpacity(0.07),
              size: 160,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
        ),
      ),
    );
  }
}

// ── Status banner ────────────────────────────────────────────────────────────
class _StatusBanner extends StatelessWidget {
  const _StatusBanner();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConverterProvider>();

    String text;
    Color color;
    IconData icon;

    switch (provider.loadState) {
      case LoadState.loading:
        text = 'Fetching live rates…';
        color = Colors.white38;
        icon = Icons.sync_rounded;
        break;
      case LoadState.error:
        text = 'Using cached rates';
        color = const Color(0xFFFF6B35).withOpacity(0.7);
        icon = Icons.wifi_off_rounded;
        break;
      case LoadState.idle:
        final ts = provider.lastUpdated;
        text = ts != null
            ? 'Updated ${DateFormat('HH:mm').format(ts)}'
            : 'Live exchange rates';
        color = Colors.white30;
        icon = Icons.check_circle_outline_rounded;
        break;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 5),
        Text(text,
            style: GoogleFonts.dmSans(
                fontSize: 11, color: color, letterSpacing: 0.3)),
      ],
    );
  }
}