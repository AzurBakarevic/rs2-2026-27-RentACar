import 'package:intl/intl.dart';

final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');
final DateFormat _apiDateFormat = DateFormat('yyyy-MM-dd');

String formatDate(DateTime value) => _dateFormat.format(value.toLocal());

String toApiDate(DateTime value) => _apiDateFormat.format(value);
