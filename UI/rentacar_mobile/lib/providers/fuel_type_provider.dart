import '../models/fuel_type.dart';
import 'base_provider.dart';

class FuelTypeProvider extends BaseProvider<FuelType> {
  FuelTypeProvider() : super('FuelTypes');

  @override
  FuelType fromJson(data) {
    return FuelType.fromJson(data);
  }
}
