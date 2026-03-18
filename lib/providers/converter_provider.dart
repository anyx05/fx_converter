// lib/providers/converter_provider.dart

import 'package:flutter/foundation.dart';
import '../models/currency.dart';
import '../services/exchange_rate_service.dart';

enum LoadState { idle, loading, error }

class ConverterProvider extends ChangeNotifier {
  final ExchangeRateService _service = ExchangeRateService();

  // ── Selected currencies ──────────────────────────────────────────────────
  Currency _c1 = kSupportedCurrencies[0]; // USD
  Currency _c2 = kSupportedCurrencies[1]; // EUR

  // ── Display values ───────────────────────────────────────────────────────
  String _v1 = '0';
  String _v2 = '0';

  // ── Active card ──────────────────────────────────────────────────────────
  int _activeCard = 1;

  // ── When true, next digit replaces the whole value instead of appending.
  // This gives the "show 1, then start fresh on first keypress" behaviour.
  bool _replaceOnNextInput = false;

  // ── Fetch state ──────────────────────────────────────────────────────────
  LoadState _loadState = LoadState.idle;
  String _errorMessage = '';
  DateTime? _lastUpdated;

  // ── Getters ──────────────────────────────────────────────────────────────
  Currency get c1 => _c1;
  Currency get c2 => _c2;
  String get v1 => _v1;
  String get v2 => _v2;
  int get activeCard => _activeCard;
  LoadState get loadState => _loadState;
  String get errorMessage => _errorMessage;
  DateTime? get lastUpdated => _lastUpdated;

  // ── Init ─────────────────────────────────────────────────────────────────
  ConverterProvider() {
    // Start with both cards at 0 — no network call needed
  }

  // ── Tap a card ───────────────────────────────────────────────────────────
  // Show "1" immediately and mark that the next keypress should replace it.
  void setActiveCard(int card) {
    _activeCard = card;
    _setValue(card, '1');
    _replaceOnNextInput = true;
    // Compute the other card's value from 1
    _convertFromCard(card);
    notifyListeners();
  }

  // ── Currency dropdown changed ─────────────────────────────────────────────
  void setCurrency(int card, Currency currency) {
    if (card == 1) {
      _c1 = currency;
    } else {
      _c2 = currency;
    }
    // Same as tapping the card — reset to 1 and flag replace
    _setValue(card, '1');
    _activeCard = card;
    _replaceOnNextInput = true;
    _convertFromCard(card);
    notifyListeners();
  }

  // ── Swap currencies and their values ─────────────────────────────────────
  void swap() {
    final tmpCurrency = _c1;
    _c1 = _c2;
    _c2 = tmpCurrency;

    final tmpValue = _v1;
    _v1 = _v2;
    _v2 = tmpValue;

    // Active card stays the same but now has a different currency,
    // so recompute the other card
    _convertFromCard(_activeCard);
    notifyListeners();
  }

  // ── Keypad input ──────────────────────────────────────────────────────────
  void onKey(String key) {
    if (key == 'C') {
      // Clear: both cards → '0', no conversion needed (0 × anything = 0)
      _v1 = '0';
      _v2 = '0';
      _replaceOnNextInput = false;
      notifyListeners();
      return;
    }

    final current = _getValueForCard(_activeCard);

    if (key == '⌫') {
      final next = current.length <= 1 ? '0' : current.substring(0, current.length - 1);
      _setValue(_activeCard, next);
      _replaceOnNextInput = false;
      _convertFromCard(_activeCard);
      return;
    }

    if (key == '.') {
      if (_replaceOnNextInput) {
        // Start a decimal from scratch: "0."
        _setValue(_activeCard, '0.');
        _replaceOnNextInput = false;
        _convertFromCard(_activeCard);
        return;
      }
      if (current.contains('.')) return; // already has a decimal
      _setValue(_activeCard, '$current.');
      _convertFromCard(_activeCard);
      return;
    }

    // ── Digit or '00' ──────────────────────────────────────────────────────
    if (_replaceOnNextInput) {
      // First keypress after card tap — replace entire value
      _setValue(_activeCard, key == '00' ? '0' : key);
      _replaceOnNextInput = false;
      _convertFromCard(_activeCard);
      return;
    }

    // Normal append
    if (key == '00') {
      if (current == '0') return;
      if (current.length >= 11) return;
      _setValue(_activeCard, '${current}00');
    } else {
      if (current == '0') {
        _setValue(_activeCard, key);
      } else {
        if (current.length >= 12) return;
        _setValue(_activeCard, '$current$key');
      }
    }
    _convertFromCard(_activeCard);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _getValueForCard(int card) => card == 1 ? _v1 : _v2;

  void _setValue(int card, String val) {
    if (card == 1) {
      _v1 = val;
    } else {
      _v2 = val;
    }
  }

  Currency _getCurrencyForCard(int card) => card == 1 ? _c1 : _c2;

  Future<void> _convertFromCard(int sourceCard) async {
    final raw = _getValueForCard(sourceCard);
    final amount = double.tryParse(raw) ?? 0.0;

    // If amount is zero, just set the other card to '0' — no API call needed
    if (amount == 0) {
      final targetCard = sourceCard == 1 ? 2 : 1;
      _setValue(targetCard, '0');
      notifyListeners();
      return;
    }

    final sourceCurrency = _getCurrencyForCard(sourceCard);
    final targetCard = sourceCard == 1 ? 2 : 1;
    final target = _getCurrencyForCard(targetCard);

    _loadState = LoadState.loading;
    notifyListeners();

    try {
      final result = await _service.convert(
        amount: amount,
        from: sourceCurrency.code,
        to: target.code,
      );
      _setValue(targetCard, _formatResult(result, target.code));
      _lastUpdated = DateTime.now();
      _loadState = LoadState.idle;
      _errorMessage = '';
    } catch (e) {
      _loadState = LoadState.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    notifyListeners();
  }

  // ── Number formatting ─────────────────────────────────────────────────────
  // Rules:
  //   • Zero input/output  → plain '0'
  //   • JPY / KRW          → no decimal places
  //   • Everything else    → exactly 4 decimal places
  String _formatResult(double value, String code) {
    if (value == 0) return '0';
    if (code == 'JPY' || code == 'KRW') return value.toStringAsFixed(0);
    return value.toStringAsFixed(4);
  }
}