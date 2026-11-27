import '../models/equipment.dart';
import 'base_provider.dart';

class EquipmentProvider extends BaseProvider<Equipment> {
  EquipmentProvider() : super('Equipment');

  @override
  Equipment fromJson(data) {
    return Equipment.fromJson(data);
  }
}
