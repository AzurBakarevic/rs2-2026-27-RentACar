import 'formatters.dart';

final RegExp _decimalPattern = RegExp(r'^-?\d+([.,]\d+)?$');
final RegExp _integerPattern = RegExp(r'^-?\d+$');

String? Function(String?) decimalValidator({
  required String requiredMessage,
  required String? Function(double value) range,
  required String decimalsMessage,
  int maxDecimals = 2,
}) {
  return (text) {
    final trimmed = text?.trim() ?? '';
    if (trimmed.isEmpty) {
      return requiredMessage;
    }
    if (!_decimalPattern.hasMatch(trimmed)) {
      return 'Unesite broj, npr. 70,50.';
    }
    final separator = trimmed.indexOf(RegExp('[.,]'));
    if (separator >= 0 && trimmed.length - separator - 1 > maxDecimals) {
      return decimalsMessage;
    }
    return range(parseDecimal(trimmed)!);
  };
}

String? Function(String?) integerValidator({
  required String requiredMessage,
  required int min,
  required int max,
  required String rangeMessage,
}) {
  return (text) {
    final trimmed = text?.trim() ?? '';
    if (trimmed.isEmpty) {
      return requiredMessage;
    }
    if (!_integerPattern.hasMatch(trimmed)) {
      return 'Unesite cijeli broj.';
    }
    final value = int.parse(trimmed);
    return value < min || value > max ? rangeMessage : null;
  };
}

String? Function(String?) maxLengthText(int maxLength, String message) {
  return (value) => (value?.trim().length ?? 0) > maxLength ? message : null;
}

String? Function(T?) requiredValue<T>(String message) {
  return (value) => value == null ? message : null;
}
