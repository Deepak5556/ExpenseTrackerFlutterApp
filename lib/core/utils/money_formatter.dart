import 'package:intl/intl.dart';

/// Formats integer minor units (paise) for display without doing money math
/// with doubles. Whole rupees omit decimals; non-zero paise show two digits.
String formatMoney(
  int minorUnits, {
  bool compact = false,
  String locale = 'en_IN',
}) {
  final bool isNegative = minorUnits < 0;
  final int absoluteMinorUnits = minorUnits.abs();

  if (compact) {
    final String compactValue = NumberFormat.compactCurrency(
      locale: locale,
      symbol: '₹',
      decimalDigits: 1,
    ).format(absoluteMinorUnits / 100);
    return '${isNegative ? '−' : ''}$compactValue';
  }

  final int rupees = absoluteMinorUnits ~/ 100;
  final int paise = absoluteMinorUnits % 100;
  final String wholeRupees = NumberFormat.currency(
    locale: locale,
    symbol: '₹',
    decimalDigits: 0,
  ).format(rupees);
  final String fraction = paise == 0
      ? ''
      : '.${paise.toString().padLeft(2, '0')}';

  return '${isNegative ? '−' : ''}$wholeRupees$fraction';
}
