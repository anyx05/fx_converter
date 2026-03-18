// lib/services/exchange_rate_service.dart
//
// Strategy:
//   • Always fetch with USD as the single base currency.
//   • Cross-rates (e.g. EUR→GBP) are computed locally:
//       rate = (1 / usdRates[from]) * usdRates[to]
//   • Rates are persisted to SharedPreferences and reused for 6 hours.
//   • A network call is only made when:
//       1. No cached data exists.
//       2. The cached data is older than 6 hours.
//       3. The user explicitly calls forceRefresh().

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExchangeRateService {
  static final ExchangeRateService _instance = ExchangeRateService._();
  factory ExchangeRateService() => _instance;
  ExchangeRateService._();

  static const _prefRates     = 'cached_rates_usd';
  static const _prefTimestamp = 'cached_rates_timestamp';
  static const _cacheDuration = Duration(hours: 6);

  // In-memory copy so we don't hit SharedPreferences on every keystroke
  Map<String, double>? _memoryRates;
  DateTime?            _memoryTimestamp;

  static String get _apiKey => dotenv.env['EXCHANGE_RATE_API_KEY'] ?? '';

  // ── Public API ──────────────────────────────────────────────────────────

  /// Returns the converted amount from [from] → [to].
  /// Uses cached rates; only fetches from network when the cache is stale.
  Future<double> convert({
    required double amount,
    required String from,
    required String to,
  }) async {
    if (from == to) return amount;
    final rates = await _getRates();
    return _crossConvert(amount: amount, from: from, to: to, rates: rates);
  }

  /// Force a fresh fetch regardless of cache age (e.g. refresh button).
  Future<void> forceRefresh() async {
    _memoryRates     = null;
    _memoryTimestamp = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefRates);
    await prefs.remove(_prefTimestamp);
    await _getRates();
  }

  // ── Internal ────────────────────────────────────────────────────────────

  Future<Map<String, double>> _getRates() async {
    // 1. Return in-memory rates if still fresh
    if (_memoryRates != null && _memoryTimestamp != null) {
      if (DateTime.now().difference(_memoryTimestamp!) < _cacheDuration) {
        return _memoryRates!;
      }
    }

    // 2. Try loading from SharedPreferences
    final prefs     = await SharedPreferences.getInstance();
    final stored    = prefs.getString(_prefRates);
    final storedTs  = prefs.getInt(_prefTimestamp);

    if (stored != null && storedTs != null) {
      final savedAt = DateTime.fromMillisecondsSinceEpoch(storedTs);
      if (DateTime.now().difference(savedAt) < _cacheDuration) {
        final decoded = (jsonDecode(stored) as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, (v as num).toDouble()));
        _memoryRates     = decoded;
        _memoryTimestamp = savedAt;
        return decoded;
      }
    }

    // 3. Fetch from network
    return _fetchFromNetwork(prefs);
  }

  Future<Map<String, double>> _fetchFromNetwork(
      SharedPreferences prefs) async {
    final apiKey = _apiKey;

    if (apiKey.isEmpty || apiKey == 'your_api_key_here') {
      // No key configured — return mock rates so the UI still works
      final mock = _mockRates();
      _memoryRates     = mock;
      _memoryTimestamp = DateTime.now();
      return mock;
    }

    final url = Uri.parse(
      'https://v6.exchangerate-api.com/v6/$apiKey/latest/USD',
    );

    final response =
        await http.get(url).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['result'] != 'success') {
      throw Exception(body['error-type'] ?? 'API error');
    }

    final rates = (body['conversion_rates'] as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, (v as num).toDouble()));

    // Persist
    final now = DateTime.now();
    await prefs.setString(_prefRates, jsonEncode(rates));
    await prefs.setInt(_prefTimestamp, now.millisecondsSinceEpoch);

    _memoryRates     = rates;
    _memoryTimestamp = now;
    return rates;
  }

  /// Cross-rate math: from → USD → to  (avoids needing per-base fetches)
  double _crossConvert({
    required double amount,
    required String from,
    required String to,
    required Map<String, double> rates,
  }) {
    final fromRate = rates[from];
    final toRate   = rates[to];
    if (fromRate == null || toRate == null) {
      throw Exception('Unknown currency code: $from or $to');
    }
    // amount in [from] → amount in USD → amount in [to]
    final amountInUsd = amount / fromRate;
    return amountInUsd * toRate;
  }

  // ── Mock rates (USD base, used when no API key is set) ──────────────────
  Map<String, double> _mockRates() => {
    'USD': 1.0,    'EUR': 0.921,  'GBP': 0.789,  'JPY': 149.5,
    'CAD': 1.354,  'AUD': 1.531,  'CHF': 0.883,  'CNY': 7.236,
    'INR': 83.12,  'MXN': 17.15,  'BRL': 4.972,  'KRW': 1325.0,
    'SGD': 1.343,  'HKD': 7.824,  'NOK': 10.56,  'SEK': 10.44,
    'NZD': 1.627,  'ZAR': 18.63,  'AED': 3.673,  'TRY': 30.45,
    'SAR': 3.751,  'PLN': 3.985,  'THB': 35.12,
  };
}
