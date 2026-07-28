const Map<String, String> _currencySymbols = {
  'USD': '\$',
  'EUR': '€',
  'JPY': '¥',
  'GBP': '£',
};

String currencySymbol(String currencyCode) => _currencySymbols[currencyCode] ?? '$currencyCode ';

/// Formats [amount] with the symbol for [currencyCode], e.g. `$1,450` or
/// `¥2,430`. Amounts are shown as whole units across the app (no cents),
/// matching how the family actually thinks about trip spending.
String formatMoney(double amount, String currencyCode) {
  return '${currencySymbol(currencyCode)}${amount.toStringAsFixed(0)}';
}

const List<String> supportedCurrencies = ['USD', 'EUR', 'JPY', 'GBP'];
