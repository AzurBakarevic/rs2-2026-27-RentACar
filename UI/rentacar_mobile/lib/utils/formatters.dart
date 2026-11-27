import 'package:intl/intl.dart';

final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');
final DateFormat _shortDateFormat = DateFormat('dd.MM.');
final DateFormat _timeFormat = DateFormat('HH:mm');
final DateFormat _apiDateFormat = DateFormat('yyyy-MM-dd');
final NumberFormat _moneyFormat = NumberFormat('#,##0.00', 'bs');
final NumberFormat _decimalFormat = NumberFormat('#,##0.##', 'bs');
final NumberFormat _ratingFormat = NumberFormat('0.0', 'bs');
final NumberFormat _decimalInputFormat = NumberFormat('0.##', 'bs');

String formatDate(DateTime value) => _dateFormat.format(value.toLocal());

String formatTime(DateTime value) => _timeFormat.format(value.toLocal());

String formatDateTime(DateTime value) => '${formatDate(value)} ${formatTime(value)}';

const List<String> _weekdayNames = ['Pon', 'Uto', 'Sri', 'Čet', 'Pet', 'Sub', 'Ned'];

const List<String> _monthNames = [
  'Januar',
  'Februar',
  'Mart',
  'April',
  'Maj',
  'Juni',
  'Juli',
  'August',
  'Septembar',
  'Oktobar',
  'Novembar',
  'Decembar',
];

String formatWeekdayShort(DateTime value) => _weekdayNames[value.toLocal().weekday - 1];

String formatMonthName(DateTime value) => _monthNames[value.toLocal().month - 1];

String formatDateRange(DateTime from, DateTime to) {
  final start = from.toLocal();
  final end = to.toLocal();
  if (start.year == end.year && start.month == end.month && start.day == end.day) {
    return formatDate(start);
  }
  if (start.year != end.year) {
    return '${formatDate(start)} – ${formatDate(end)}';
  }
  return '${_shortDateFormat.format(start)} – ${formatDate(end)}';
}

String formatDays(int days) => days % 10 == 1 && days % 100 != 11 ? '$days dan' : '$days dana';

String formatCountdown(Duration value) {
  final seconds = value.isNegative ? 0 : value.inSeconds;
  final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
  return '$minutes:${(seconds % 60).toString().padLeft(2, '0')}';
}

String toApiDate(DateTime value) => _apiDateFormat.format(value);

String formatMoney(num value) => '${_moneyFormat.format(value)} KM';

String formatPricePerDay(num value) => '${_decimalFormat.format(value)} KM/dan';

String formatRating(num value) => _ratingFormat.format(value);

String formatDecimalInput(num value) => _decimalInputFormat.format(value);

double? parseDecimal(String? text) {
  final normalized = (text ?? '').trim().replaceAll(',', '.');
  return normalized.isEmpty ? null : double.tryParse(normalized);
}
