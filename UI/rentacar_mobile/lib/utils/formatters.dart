import 'package:intl/intl.dart';

final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');
final DateFormat _timeFormat = DateFormat('HH:mm');
final DateFormat _apiDateFormat = DateFormat('yyyy-MM-dd');
final NumberFormat _moneyFormat = NumberFormat('#,##0.00', 'bs');
final NumberFormat _decimalFormat = NumberFormat('#,##0.##', 'bs');
final NumberFormat _ratingFormat = NumberFormat('0.0', 'bs');
final NumberFormat _decimalInputFormat = NumberFormat('0.##', 'bs');

String formatDate(DateTime value) => _dateFormat.format(value.toLocal());

String formatTime(DateTime value) => _timeFormat.format(value.toLocal());

String formatDateTime(DateTime value) => '${formatDate(value)} ${formatTime(value)}';

String toApiDate(DateTime value) => _apiDateFormat.format(value);

String formatMoney(num value) => '${_moneyFormat.format(value)} KM';

String formatPricePerDay(num value) => '${_decimalFormat.format(value)} KM/dan';

String formatRating(num value) => _ratingFormat.format(value);

String formatDecimalInput(num value) => _decimalInputFormat.format(value);

double? parseDecimal(String? text) {
  final normalized = (text ?? '').trim().replaceAll(',', '.');
  return normalized.isEmpty ? null : double.tryParse(normalized);
}
