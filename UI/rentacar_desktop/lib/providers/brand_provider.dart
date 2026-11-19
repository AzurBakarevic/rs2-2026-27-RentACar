import '../models/brand.dart';
import 'base_provider.dart';

class BrandProvider extends BaseProvider<Brand> {
  BrandProvider() : super('Brands');

  @override
  Brand fromJson(data) {
    return Brand.fromJson(data);
  }
}
