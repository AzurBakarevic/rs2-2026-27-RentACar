class RentalPeriod {
  const RentalPeriod({required this.pickupAt, required this.returnAt});

  static const int maxRentalDays = 30;
  static const int defaultPickupHour = 9;
  static const int defaultRentalDays = 3;

  final DateTime pickupAt;
  final DateTime returnAt;

  factory RentalPeriod.initial(DateTime now) {
    final pickupAt = DateTime(now.year, now.month, now.day + 1, defaultPickupHour);
    final returnAt = DateTime(pickupAt.year, pickupAt.month, pickupAt.day + defaultRentalDays, defaultPickupHour);
    return RentalPeriod(pickupAt: pickupAt, returnAt: returnAt);
  }

  int get rentalDays {
    final duration = returnAt.difference(pickupAt).inMicroseconds;
    return (duration + Duration.microsecondsPerDay - 1) ~/ Duration.microsecondsPerDay;
  }

  RentalPeriod withPickup(DateTime value) {
    final days = _calendarDate(returnAt).difference(_calendarDate(pickupAt)).inDays;
    var shiftedReturn = DateTime(value.year, value.month, value.day + days, returnAt.hour, returnAt.minute);
    if (!shiftedReturn.isAfter(value)) {
      shiftedReturn = DateTime(value.year, value.month, value.day + 1, value.hour, value.minute);
    }
    return RentalPeriod(pickupAt: value, returnAt: shiftedReturn);
  }

  RentalPeriod withReturn(DateTime value) => RentalPeriod(pickupAt: pickupAt, returnAt: value);

  String? validate(DateTime now) {
    if (!pickupAt.isAfter(now)) {
      return 'Vrijeme preuzimanja mora biti u budućnosti.';
    }
    if (!returnAt.isAfter(pickupAt)) {
      return 'Vrijeme vraćanja mora biti poslije vremena preuzimanja.';
    }
    if (rentalDays > maxRentalDays) {
      return 'Najam može trajati najviše $maxRentalDays dana.';
    }
    return null;
  }

  static DateTime _calendarDate(DateTime value) => DateTime.utc(value.year, value.month, value.day);
}
