import '../models/vehicle_model.dart';
import 'base_provider.dart';

class VehicleModelProvider extends BaseProvider<VehicleModel> {
  VehicleModelProvider() : super('VehicleModels');

  @override
  VehicleModel fromJson(data) {
    return VehicleModel.fromJson(data);
  }
}
