import 'package:intl/intl.dart';

final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');
final DateFormat _timeFormat = DateFormat('HH:mm');
final DateFormat _apiDateFormat = DateFormat('yyyy-MM-dd');
final NumberFormat _moneyFormat = NumberFormat('#,##0.00', 'bs');
final NumberFormat _decimalFormat = NumberFormat('#,##0.##', 'bs');
final NumberFormat _decimalInputFormat = NumberFormat('0.##', 'bs');

const List<String> _weekdayNames = ['Pon', 'Uto', 'Sri', 'Čet', 'Pet', 'Sub', 'Ned'];

String formatDate(DateTime value) => _dateFormat.format(value.toLocal());

String formatTime(DateTime value) => _timeFormat.format(value.toLocal());

String formatDateTime(DateTime value) => '${formatDate(value)} ${formatTime(value)}';

String formatWeekday(DateTime value) => _weekdayNames[value.weekday - 1];

String formatMoney(num value) => '${_moneyFormat.format(value)} KM';

String formatIncrease(num value) => '+${_decimalFormat.format(value)}%';

String toApiDate(DateTime value) => _apiDateFormat.format(value);

String formatDecimalInput(num value) => _decimalInputFormat.format(value);

double? parseDecimal(String? text) {
  final normalized = (text ?? '').trim().replaceAll(',', '.');
  return normalized.isEmpty ? null : double.tryParse(normalized);
}

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
