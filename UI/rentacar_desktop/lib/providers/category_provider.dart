import '../models/category.dart';
import 'base_provider.dart';

class CategoryProvider extends BaseProvider<Category> {
  CategoryProvider() : super('Categories');

  @override
  Category fromJson(data) {
    return Category.fromJson(data);
  }
}
