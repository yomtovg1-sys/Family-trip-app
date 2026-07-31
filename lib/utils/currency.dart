import 'world_countries.dart';

const Map<String, String> _currencySymbols = {
  'USD': '\$',
  'EUR': '€',
  'JPY': '¥',
  'CNY': '¥',
  'GBP': '£',
  'INR': '₹',
  'KRW': '₩',
  'THB': '฿',
  'VND': '₫',
  'RUB': '₽',
  'TRY': '₺',
  'AUD': '\$',
  'CAD': '\$',
  'NZD': '\$',
  'MXN': '\$',
  'BRL': 'R\$',
  'CHF': 'Fr',
  'ZAR': 'R',
  'ILS': '₪',
  'PHP': '₱',
};

String currencySymbol(String currencyCode) => _currencySymbols[currencyCode] ?? '$currencyCode ';

/// Formats [amount] with the symbol for [currencyCode], e.g. `$1,450` or
/// `¥2,430`. Amounts are shown as whole units across the app (no cents),
/// matching how the family actually thinks about trip spending.
String formatMoney(double amount, String currencyCode) {
  return '${currencySymbol(currencyCode)}${amount.toStringAsFixed(0)}';
}

/// Every currency code a trip or expense can be tagged with — derived from
/// [worldCountries] so it never drifts out of sync with the country list.
final List<String> supportedCurrencies = {for (final c in worldCountries) c.currency}.toList()..sort();
