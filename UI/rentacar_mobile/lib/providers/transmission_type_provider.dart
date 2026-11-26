import '../models/transmission_type.dart';
import 'base_provider.dart';

class TransmissionTypeProvider extends BaseProvider<TransmissionType> {
  TransmissionTypeProvider() : super('TransmissionTypes');

  @override
  TransmissionType fromJson(data) {
    return TransmissionType.fromJson(data);
  }
}
