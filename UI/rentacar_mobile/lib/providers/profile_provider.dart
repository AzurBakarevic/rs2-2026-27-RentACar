import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/user.dart';
import '../utils/image_file_picker.dart';
import 'base_provider.dart';

class ProfileProvider with ChangeNotifier {
  static const String _endpoint = 'Profile';

  User? _profile;
  int _imageVersion = 0;

  User? get profile => _profile;

  String get imageUrl => BaseProvider.buildUri('$_endpoint/Image', {'v': _imageVersion}).toString();

  Map<String, String> imageHeaders() => BaseProvider.createHeaders()..remove('Content-Type');

  Future<User> load() async {
    final response = await BaseProvider.send(
      () => http.get(BaseProvider.buildUri(_endpoint), headers: BaseProvider.createHeaders()),
    );
    _imageVersion++;
    return _setProfile(User.fromJson(jsonDecode(response.body)));
  }

  Future<User> update(Map<String, dynamic> request) async {
    final response = await BaseProvider.send(
      () => http.put(BaseProvider.buildUri(_endpoint), headers: BaseProvider.createHeaders(), body: jsonEncode(request)),
    );
    return _setProfile(User.fromJson(jsonDecode(response.body)));
  }

  Future<void> changePassword(Map<String, dynamic> request) async {
    await BaseProvider.send(
      () => http.put(
        BaseProvider.buildUri('$_endpoint/Password'),
        headers: BaseProvider.createHeaders(),
        body: jsonEncode(request),
      ),
    );
  }

  Future<void> updateImage(PickedImage image) async {
    await BaseProvider.send(() async {
      final request = http.MultipartRequest('PUT', BaseProvider.buildUri('$_endpoint/Image'))
        ..headers.addAll(imageHeaders())
        ..files.add(http.MultipartFile.fromBytes(
          'image',
          image.bytes,
          filename: image.name,
          contentType: MediaType.parse(image.contentType),
        ));
      return http.Response.fromStream(await request.send());
    });
    _setImage(true);
  }

  Future<void> deleteImage() async {
    await BaseProvider.send(
      () => http.delete(BaseProvider.buildUri('$_endpoint/Image'), headers: BaseProvider.createHeaders()),
    );
    _setImage(false);
  }

  User _setProfile(User profile) {
    _profile = profile;
    notifyListeners();
    return profile;
  }

  void _setImage(bool hasImage) {
    final profile = _profile;
    if (profile == null) {
      return;
    }
    _imageVersion++;
    _setProfile(profile.withProfileImage(hasImage));
  }
}
