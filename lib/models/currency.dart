// lib/models/currency.dart

class Currency {
  final String code;
  final String name;
  final String flag;

  const Currency({
    required this.code,
    required this.name,
    required this.flag,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Currency && other.code == code);

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => '$flag  $code';
}

// ── Supported currencies ────────────────────────────────────────────────────
const List<Currency> kSupportedCurrencies = [
  Currency(code: 'USD', name: 'US Dollar',          flag: '🇺🇸'),
  Currency(code: 'EUR', name: 'Euro',                flag: '🇪🇺'),
  Currency(code: 'GBP', name: 'British Pound',       flag: '🇬🇧'),
  Currency(code: 'JPY', name: 'Japanese Yen',        flag: '🇯🇵'),
  Currency(code: 'CAD', name: 'Canadian Dollar',     flag: '🇨🇦'),
  Currency(code: 'AUD', name: 'Australian Dollar',   flag: '🇦🇺'),
  Currency(code: 'CHF', name: 'Swiss Franc',         flag: '🇨🇭'),
  Currency(code: 'CNY', name: 'Chinese Yuan',        flag: '🇨🇳'),
  Currency(code: 'INR', name: 'Indian Rupee',        flag: '🇮🇳'),
  Currency(code: 'MXN', name: 'Mexican Peso',        flag: '🇲🇽'),
  Currency(code: 'BRL', name: 'Brazilian Real',      flag: '🇧🇷'),
  Currency(code: 'KRW', name: 'South Korean Won',    flag: '🇰🇷'),
  Currency(code: 'SGD', name: 'Singapore Dollar',    flag: '🇸🇬'),
  Currency(code: 'HKD', name: 'Hong Kong Dollar',    flag: '🇭🇰'),
  Currency(code: 'NOK', name: 'Norwegian Krone',     flag: '🇳🇴'),
  Currency(code: 'SEK', name: 'Swedish Krona',       flag: '🇸🇪'),
  Currency(code: 'DKK', name: 'Danish Krone',        flag: '🇩🇰'),
  Currency(code: 'NZD', name: 'New Zealand Dollar',  flag: '🇳🇿'),
  Currency(code: 'ZAR', name: 'South African Rand',  flag: '🇿🇦'),
  Currency(code: 'AED', name: 'UAE Dirham',          flag: '🇦🇪'),
  Currency(code: 'TRY', name: 'Turkish Lira',        flag: '🇹🇷'),
  Currency(code: 'SAR', name: 'Saudi Riyal',         flag: '🇸🇦'),
  Currency(code: 'RUB', name: 'Russian Ruble',       flag: '🇷🇺'),
  Currency(code: 'PLN', name: 'Polish Zloty',        flag: '🇵🇱'),
  Currency(code: 'THB', name: 'Thai Baht',           flag: '🇹🇭'),
];
