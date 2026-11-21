import '../models/vehicle_maintenance.dart';
import 'base_provider.dart';

class VehicleMaintenanceProvider extends BaseProvider<VehicleMaintenance> {
  VehicleMaintenanceProvider() : super('VehicleMaintenances');

  @override
  VehicleMaintenance fromJson(data) {
    return VehicleMaintenance.fromJson(data);
  }
}
