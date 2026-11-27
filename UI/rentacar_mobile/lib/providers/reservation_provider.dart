import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/payment_intent.dart';
import '../models/reservation.dart';
import '../models/reservation_calculation.dart';
import 'base_provider.dart';

class ReservationProvider extends BaseProvider<Reservation> {
  ReservationProvider() : super('Reservations');

  @override
  Reservation fromJson(data) {
    return Reservation.fromJson(data);
  }

  static Map<String, dynamic> createRequest({
    required int vehicleId,
    required DateTime pickupAt,
    required DateTime returnAt,
    required Map<int, int> equipment,
  }) {
    return {
      'vehicleId': vehicleId,
      'pickupAt': pickupAt.toUtc().toIso8601String(),
      'returnAt': returnAt.toUtc().toIso8601String(),
      'equipment': [
        for (final item in equipment.entries)
          if (item.value > 0) {'equipmentId': item.key, 'quantity': item.value},
      ],
    };
  }

  Future<ReservationCalculation> calculate(Map<String, dynamic> request) async {
    final response = await _post('$endpoint/Calculate', request);
    return ReservationCalculation.fromJson(jsonDecode(response.body));
  }

  @override
  Future<Reservation> insert(Map<String, dynamic> request) async {
    final reservation = await super.insert(request);
    notifyListeners();
    return reservation;
  }

  Future<PaymentIntent> createPayment(int id) async {
    final response = await _post('$endpoint/$id/Payment');
    return PaymentIntent.fromJson(jsonDecode(response.body));
  }

  Future<Reservation> confirmPayment(int id) async {
    final response = await _post('$endpoint/$id/Payment/Confirm');
    notifyListeners();
    return fromJson(jsonDecode(response.body));
  }

  Future<Reservation> cancel(int id) async {
    final response = await _post('$endpoint/$id/Cancel');
    notifyListeners();
    return fromJson(jsonDecode(response.body));
  }

  void reservationChanged() => notifyListeners();

  Future<http.Response> _post(String path, [Map<String, dynamic>? body]) {
    final uri = BaseProvider.buildUri(path);
    return BaseProvider.send(
      () => http.post(uri, headers: BaseProvider.createHeaders(), body: body == null ? null : jsonEncode(body)),
    );
  }
}
