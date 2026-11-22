import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/reservation.dart';
import 'base_provider.dart';

class ReservationProvider extends BaseProvider<Reservation> {
  ReservationProvider() : super('Reservations');

  @override
  Reservation fromJson(data) {
    return Reservation.fromJson(data);
  }

  /// Status se mijenja samo kroz akcije state machine-a (upute 7); [reason] ide uz odbijanje i otkazivanje.
  Future<Reservation> performAction(int id, ReservationAction action, {String? reason}) async {
    final uri = BaseProvider.buildUri('$endpoint/$id/${action.apiName}');
    final body = reason == null ? null : jsonEncode({'reason': reason});
    final response = await BaseProvider.send(() => http.post(uri, headers: BaseProvider.createHeaders(), body: body));
    return fromJson(jsonDecode(response.body));
  }
}
