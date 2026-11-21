import 'package:intl/intl.dart';

// Prikaz kao na skicama: 02.11.2026, 08:00, 70,00 KM, +20%.
final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');
final DateFormat _timeFormat = DateFormat('HH:mm');
final DateFormat _apiDateFormat = DateFormat('yyyy-MM-dd');
final NumberFormat _moneyFormat = NumberFormat('#,##0.00', 'bs');
final NumberFormat _decimalFormat = NumberFormat('#,##0.##', 'bs');
final NumberFormat _decimalInputFormat = NumberFormat('0.##', 'bs');

const List<String> _weekdayNames = ['Pon', 'Uto', 'Sri', 'Čet', 'Pet', 'Sub', 'Ned'];

/// API šalje vremena u UTC-u, a prikazuju se po lokalnom vremenu računara.
String formatDate(DateTime value) => _dateFormat.format(value.toLocal());

String formatTime(DateTime value) => _timeFormat.format(value.toLocal());

String formatDateTime(DateTime value) => '${formatDate(value)} ${formatTime(value)}';

/// Skraćeni naziv dana u sedmici, npr. „Pon”.
String formatWeekday(DateTime value) => _weekdayNames[value.weekday - 1];

String formatMoney(num value) => '${_moneyFormat.format(value)} KM';

/// Uvećanje cijene u procentima, npr. „+20%” ili „+12,5%”.
String formatIncrease(num value) => '+${_decimalFormat.format(value)}%';

/// Datum bez vremena za API (DateOnly), npr. "2026-06-01".
String toApiDate(DateTime value) => _apiDateFormat.format(value);

/// Vrijednost za polje forme: 70 → "70", 70.5 → "70,5".
String formatDecimalInput(num value) => _decimalInputFormat.format(value);

/// Decimalni broj iz polja forme; prihvata i zarez i tačku (70,50 i 70.50).
double? parseDecimal(String? text) {
  final normalized = (text ?? '').trim().replaceAll(',', '.');
  return normalized.isEmpty ? null : double.tryParse(normalized);
}

/// Bosanski ima tri oblika: 1 rezervacija, 2–4 rezervacije, 5 i više (i 11–14) rezervacija.
String pluralBs(int count, String one, String few, String many) {
  final lastDigit = count % 10;
  final lastTwoDigits = count % 100;
  if (lastDigit == 1 && lastTwoDigits != 11) {
    return one;
  }
  if (lastDigit >= 2 && lastDigit <= 4 && (lastTwoDigits < 12 || lastTwoDigits > 14)) {
    return few;
  }
  return many;
}
