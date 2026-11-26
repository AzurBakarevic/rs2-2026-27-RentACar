const int nameMaxLength = 50;
const int emailMaxLength = 100;
const int usernameMinLength = 3;
const int usernameMaxLength = 50;
const int passwordMinLength = 8;
const int passwordMaxLength = 100;
const int driverLicenseNumberMaxLength = 30;
const int resetCodeLength = 6;

final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+$');
final RegExp _phonePattern = RegExp(r'^\+?[0-9][0-9 /-]{5,28}$');
final RegExp _usernamePattern = RegExp(r'^[a-zA-Z0-9._-]+$');
final RegExp _resetCodePattern = RegExp('^[0-9]{$resetCodeLength}\$');

String? validateFirstName(String? value) => _validateName(value, 'Ime je obavezno.', 'Ime');

String? validateLastName(String? value) => _validateName(value, 'Prezime je obavezno.', 'Prezime');

String? _validateName(String? value, String requiredMessage, String label) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) {
    return requiredMessage;
  }
  return text.length > nameMaxLength ? '$label može imati najviše $nameMaxLength znakova.' : null;
}

String? validateEmail(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) {
    return 'E-mail je obavezan.';
  }
  if (!_emailPattern.hasMatch(text)) {
    return 'E-mail nije ispravnog formata.';
  }
  return text.length > emailMaxLength ? 'E-mail može imati najviše $emailMaxLength znakova.' : null;
}

String? validatePhone(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) {
    return 'Broj telefona je obavezan.';
  }
  return _phonePattern.hasMatch(text) ? null : 'Broj telefona nije ispravnog formata.';
}

String? validateUsername(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) {
    return 'Korisničko ime je obavezno.';
  }
  if (text.length < usernameMinLength || text.length > usernameMaxLength) {
    return 'Korisničko ime mora imati između $usernameMinLength i $usernameMaxLength znakova.';
  }
  return _usernamePattern.hasMatch(text)
      ? null
      : 'Korisničko ime smije sadržavati samo slova bez kvačica, brojeve, tačku, crticu i donju crtu.';
}

String? validatePassword(String? value) {
  final password = value ?? '';
  if (password.isEmpty) {
    return 'Lozinka je obavezna.';
  }
  return password.length < passwordMinLength || password.length > passwordMaxLength
      ? 'Lozinka mora imati između $passwordMinLength i $passwordMaxLength znakova.'
      : null;
}

String? Function(String?) passwordConfirmValidator(String? Function() password) {
  return (value) => (value ?? '') == (password() ?? '') ? null : 'Lozinke se ne podudaraju.';
}

String? validateResetCode(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) {
    return 'Unesite kod iz e-maila.';
  }
  return _resetCodePattern.hasMatch(text) ? null : 'Kod mora imati $resetCodeLength cifara.';
}

String? validateDriverLicenseNumber(String? value, {required bool hasValidUntil}) {
  final text = value?.trim() ?? '';
  if (text.length > driverLicenseNumberMaxLength) {
    return 'Broj vozačke dozvole može imati najviše $driverLicenseNumberMaxLength znakova.';
  }
  return text.isEmpty && hasValidUntil ? 'Unesite broj vozačke dozvole.' : null;
}

String? validateDriverLicenseValidUntil(DateTime? value, {required bool hasNumber}) {
  return value == null && hasNumber ? 'Unesite datum do kojeg važi vozačka dozvola.' : null;
}
