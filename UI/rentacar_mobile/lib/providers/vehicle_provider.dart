import '../models/vehicle.dart';
import 'base_provider.dart';

class VehicleProvider extends BaseProvider<Vehicle> {
  VehicleProvider() : super('Vehicles');

  String imageUrl(int id) => BaseProvider.buildUri('$endpoint/$id/Image').toString();

  Map<String, String> imageHeaders() => BaseProvider.createHeaders()..remove('Content-Type');

  @override
  Vehicle fromJson(data) {
    return Vehicle.fromJson(data);
  }
}
