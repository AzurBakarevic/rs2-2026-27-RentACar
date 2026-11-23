import '../models/vehicle.dart';
import 'base_provider.dart';
import 'entity_image_mixin.dart';

class VehicleProvider extends BaseProvider<Vehicle> with EntityImageMixin<Vehicle> {
  VehicleProvider() : super('Vehicles');

  @override
  Vehicle fromJson(data) {
    return Vehicle.fromJson(data);
  }
}
