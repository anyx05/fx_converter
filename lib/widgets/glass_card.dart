// lib/widgets/glass_card.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/currency.dart';
import '../providers/converter_provider.dart';

class CurrencyCard extends StatelessWidget {
  final int cardIndex; // 1 or 2

  const CurrencyCard({super.key, required this.cardIndex});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConverterProvider>();
    final isActive = provider.activeCard == cardIndex;

    final currency = cardIndex == 1 ? provider.c1 : provider.c2;
    final value    = cardIndex == 1 ? provider.v1 : provider.v2;

    return GestureDetector(
      onTap: () => provider.setActiveCard(cardIndex),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? const Color(0xFFFF6B35).withOpacity(0.75)
                : Colors.white.withOpacity(0.14),
            width: isActive ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isActive
                  ? const Color(0xFFFF6B35).withOpacity(0.14)
                  : Colors.black.withOpacity(0.12),
              blurRadius: isActive ? 22 : 10,
              spreadRadius: isActive ? 1 : 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white.withOpacity(0.13)
                    : Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  // ── Left: flag + dropdown ──────────────────────────────
                  Expanded(
                    flex: 4,
                    child: _CurrencyDropdown(
                      cardIndex: cardIndex,
                      selected: currency,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // ── Right: amount ──────────────────────────────────────
                  Expanded(
                    flex: 5,
                    child: _AmountDisplay(
                      value: value,
                      isActive: isActive,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Currency dropdown ────────────────────────────────────────────────────────
class _CurrencyDropdown extends StatelessWidget {
  final int cardIndex;
  final Currency selected;

  const _CurrencyDropdown({required this.cardIndex, required this.selected});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ConverterProvider>();

    return DropdownButtonHideUnderline(
      child: DropdownButton<Currency>(
        value: selected,
        dropdownColor: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        icon: const Icon(Icons.unfold_more_rounded,
            size: 18, color: Color(0xFFAAAAAA)),
        isExpanded: true,
        items: kSupportedCurrencies.map((c) {
          return DropdownMenuItem(
            value: c,
            child: Row(
              children: [
                Text(c.flag, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(c.code,
                          style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      Text(c.name,
                          style: GoogleFonts.dmSans(
                              fontSize: 10, color: Colors.white54),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (c) {
          if (c != null) provider.setCurrency(cardIndex, c);
        },
        selectedItemBuilder: (context) => kSupportedCurrencies.map((c) {
          return Row(
            children: [
              Text(c.flag, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(c.code,
                  style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ── Amount display ────────────────────────────────────────────────────────────
class _AmountDisplay extends StatelessWidget {
  final String value;
  final bool isActive;

  const _AmountDisplay({required this.value, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final display = value.isEmpty ? '–' : value;
    final fontSize = display.length > 9 ? 18.0 : 26.0;

    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 180),
      style: GoogleFonts.dmMono(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: isActive
            ? const Color(0xFFFF6B35)
            : Colors.white.withOpacity(0.88),
        letterSpacing: -0.5,
      ),
      child: Text(
        display,
        textAlign: TextAlign.right,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
