import 'package:intl/intl.dart';

class Formatters {
  const Formatters._();

  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'en_US',
    symbol: r'$',
    decimalDigits: 2,
  );
  static final NumberFormat _integer = NumberFormat.decimalPattern('en_US');
  static final DateFormat _dateTime = DateFormat('MMM d, y HH:mm', 'en_US');

  static String currency(num value) => _currency.format(value);

  static String integer(num value) => _integer.format(value);

  static String dateTime(DateTime value) => _dateTime.format(value.toLocal());

  static String initials(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      final w = words.first;
      return (w.length >= 2 ? w.substring(0, 2) : w).toUpperCase();
    }
    return (words[0][0] + words[1][0]).toUpperCase();
  }
}
