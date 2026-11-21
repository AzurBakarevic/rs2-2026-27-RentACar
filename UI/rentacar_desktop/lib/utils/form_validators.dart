import 'formatters.dart';

// Ista pravila i poruke kao FluentValidation na backendu, da korisnik grešku vidi prije slanja.

final RegExp _decimalPattern = RegExp(r'^-?\d+([.,]\d+)?$');
final RegExp _integerPattern = RegExp(r'^-?\d+$');

/// Decimalni broj (cijena, trošak, procenat): obavezan, najviše [maxDecimals] decimala i u dozvoljenom rasponu.
/// [range] vraća poruku kad je vrijednost izvan raspona, a inače `null`.
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

/// Cijeli broj (godina, broj sjedišta, količina): obavezan i u rasponu od [min] do [max].
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

/// Neobavezan tekst s najvećom dužinom.
String? Function(String?) maxLengthText(int maxLength, String message) {
  return (value) => (value?.trim().length ?? 0) > maxLength ? message : null;
}

/// Polje s odabirom (padajuća lista, datum, vozilo) koje mora imati vrijednost.
String? Function(T?) requiredValue<T>(String message) {
  return (value) => value == null ? message : null;
}
