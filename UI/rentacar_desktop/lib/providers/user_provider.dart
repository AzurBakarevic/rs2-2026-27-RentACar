import '../models/user.dart';
import 'base_provider.dart';
import 'entity_image_mixin.dart';

class UserProvider extends BaseProvider<User> with EntityImageMixin<User> {
  UserProvider() : super('Users');

  @override
  User fromJson(data) {
    return User.fromJson(data);
  }
}
