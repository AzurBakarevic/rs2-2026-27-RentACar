import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'base_provider.dart';

mixin EntityImageMixin<T> on BaseProvider<T> {
  String imageUrl(int id) => BaseProvider.buildUri('$endpoint/$id/Image').toString();

  Map<String, String> imageHeaders() => BaseProvider.createHeaders()..remove('Content-Type');

  Future<void> updateImage(int id, Uint8List bytes, {required String fileName, required String contentType}) async {
    final uri = BaseProvider.buildUri('$endpoint/$id/Image');
    await BaseProvider.send(() async {
      final request = http.MultipartRequest('PUT', uri)
        ..headers.addAll(imageHeaders())
        ..files.add(http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: fileName,
          contentType: MediaType.parse(contentType),
        ));
      return http.Response.fromStream(await request.send());
    });
  }
}
