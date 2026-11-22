import 'package:json_annotation/json_annotation.dart';

part 'reservation.g.dart';

/// Status rezervacije; API ga šalje i prima kao broj.
enum ReservationStatus {
  @JsonValue(1)
  pending(1, 'Na čekanju'),
  @JsonValue(2)
  confirmed(2, 'Potvrđena'),
  @JsonValue(3)
  completed(3, 'Završena'),
  @JsonValue(4)
  cancelled(4, 'Otkazana');

  const ReservationStatus(this.apiValue, this.label);

  final int apiValue;
  final String label;

  /// Završena i otkazana rezervacija se više ne mijenjaju (prijava).
  bool get isFinal => this == completed || this == cancelled;
}

enum PaymentStatus {
  @JsonValue(1)
  pending('Čeka uplatu'),
  @JsonValue(2)
  paid('Plaćeno'),
  @JsonValue(3)
  refunded('Vraćeno'),
  @JsonValue(4)
  cancelled('Poništeno');

  const PaymentStatus(this.label);

  final String label;
}

/// Akcije administratora; [apiName] je naziv i u odgovoru API-ja i u adresi akcije.
enum ReservationAction {
  confirm('Confirm', 'Potvrdi'),
  reject('Reject', 'Odbij'),
  complete('Complete', 'Završi'),
  cancel('Cancel', 'Otkaži');

  const ReservationAction(this.apiName, this.label);

  final String apiName;
  final String label;

  /// Razlog se unosi pri odbijanju i otkazivanju (prijava).
  bool get requiresReason => this == reject || this == cancel;
}

/// Rezervacija za listu i detalje; opremu, uplatu i historiju statusa API šalje samo u detaljima.
@JsonSerializable()
class Reservation {
  final int id;
  final DateTime pickupAt;
  final DateTime returnAt;
  final int rentalDays;
  final double vehiclePrice;
  final double seasonalSurcharge;
  final double equipmentPrice;
  final double totalPrice;
  final ReservationStatus status;
  final DateTime createdAt;
  final bool isPaid;
  final DateTime paymentDeadline;
  final String? cancellationReason;
  final int userId;
  final String userFullName;
  final bool userHasImage;
  final int vehicleId;

  /// Marka i model, npr. „Volkswagen Golf”.
  final String vehicleName;
  final String vehicleRegistrationNumber;
  final bool vehicleHasImage;

  /// Akcije koje su sada dozvoljene.
  final List<String> allowedActions;

  /// Razlozi za akcije koje u ovom statusu postoje, ali trenutno nisu dozvoljene.
  final Map<String, String> actionBlockedReasons;

  final List<ReservationEquipment>? equipment;
  final ReservationPayment? payment;
  final List<ReservationStatusChange>? statusHistory;

  Reservation({
    required this.id,
    required this.pickupAt,
    required this.returnAt,
    required this.rentalDays,
    required this.vehiclePrice,
    required this.seasonalSurcharge,
    required this.equipmentPrice,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    required this.isPaid,
    required this.paymentDeadline,
    this.cancellationReason,
    required this.userId,
    required this.userFullName,
    required this.userHasImage,
    required this.vehicleId,
    required this.vehicleName,
    required this.vehicleRegistrationNumber,
    required this.vehicleHasImage,
    required this.allowedActions,
    required this.actionBlockedReasons,
    this.equipment,
    this.payment,
    this.statusHistory,
  });

  /// Akcije koje se prikazuju: dozvoljene i onemogućene, uvijek istim redoslijedom.
  List<ReservationAction> get actions => [
        for (final action in ReservationAction.values)
          if (allowedActions.contains(action.apiName) || actionBlockedReasons.containsKey(action.apiName)) action,
      ];

  /// Razlog zbog kojeg akcija nije dozvoljena ili `null`; pravila računa server.
  String? blockedReason(ReservationAction action) => actionBlockedReasons[action.apiName];

  factory Reservation.fromJson(Map<String, dynamic> json) => _$ReservationFromJson(json);

  Map<String, dynamic> toJson() => _$ReservationToJson(this);
}

@JsonSerializable()
class ReservationEquipment {
  final String equipmentName;
  final int quantity;
  final double pricePerDay;
  final double totalPrice;

  ReservationEquipment({
    required this.equipmentName,
    required this.quantity,
    required this.pricePerDay,
    required this.totalPrice,
  });

  factory ReservationEquipment.fromJson(Map<String, dynamic> json) => _$ReservationEquipmentFromJson(json);

  Map<String, dynamic> toJson() => _$ReservationEquipmentToJson(this);
}

@JsonSerializable()
class ReservationPayment {
  final PaymentStatus status;
  final double amount;
  final DateTime? paidAt;
  final DateTime? refundedAt;

  ReservationPayment({required this.status, required this.amount, this.paidAt, this.refundedAt});

  factory ReservationPayment.fromJson(Map<String, dynamic> json) => _$ReservationPaymentFromJson(json);

  Map<String, dynamic> toJson() => _$ReservationPaymentToJson(this);
}

/// Jedan zapis historije statusa: šta se promijenilo, kada i ko je to izvršio.
@JsonSerializable()
class ReservationStatusChange {
  /// `null` kod kreiranja rezervacije.
  final ReservationStatus? oldStatus;
  final ReservationStatus newStatus;
  final String? reason;
  final DateTime changedAt;

  /// `null` kad je promjenu izvršio sistem (npr. istek roka za plaćanje).
  final String? changedByName;

  ReservationStatusChange({
    this.oldStatus,
    required this.newStatus,
    this.reason,
    required this.changedAt,
    this.changedByName,
  });

  factory ReservationStatusChange.fromJson(Map<String, dynamic> json) => _$ReservationStatusChangeFromJson(json);

  Map<String, dynamic> toJson() => _$ReservationStatusChangeToJson(this);
}
