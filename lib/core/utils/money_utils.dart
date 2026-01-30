import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';

class MoneyUtils {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '',
    decimalDigits: 2,
    locale: 'tr_TR',
  );

  static String formatAmount(Decimal amount, {String currency = 'TRY'}) {
    final formatted = _currencyFormat.format(amount.toDouble());
    return '$formatted $currency';
  }

  static String formatAmountCompact(Decimal amount, {String currency = 'TRY'}) {
    if (amount.abs() >= Decimal.fromInt(1000000)) {
      final millions = amount / Decimal.fromInt(1000000);
      return '${_currencyFormat.format(millions.toDouble())}M $currency';
    } else if (amount.abs() >= Decimal.fromInt(1000)) {
      final thousands = amount / Decimal.fromInt(1000);
      return '${_currencyFormat.format(thousands.toDouble())}K $currency';
    }
    return formatAmount(amount, currency: currency);
  }

  static Decimal parseDecimal(String value) {
    try {
      return Decimal.parse(value.replaceAll(',', ''));
    } catch (e) {
      return Decimal.zero;
    }
  }
}
