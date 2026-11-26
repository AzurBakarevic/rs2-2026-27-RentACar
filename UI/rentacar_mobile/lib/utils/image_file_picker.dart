import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

const int _maxImageBytes = 2 * 1024 * 1024;

const String imageRequirements = 'JPG ili PNG, najviše 2 MB.';

const Map<String, String> _imageContentTypes = {'jpg': 'image/jpeg', 'jpeg': 'image/jpeg', 'png': 'image/png'};

class PickedImage {
  const PickedImage({required this.bytes, required this.name, required this.contentType});

  final Uint8List bytes;
  final String name;
  final String contentType;
}

class ImagePickResult {
  const ImagePickResult.image(PickedImage this.image) : error = null;

  const ImagePickResult.error(String this.error) : image = null;

  final PickedImage? image;
  final String? error;
}

Future<ImagePickResult?> pickImageFile(String dialogTitle) async {
  final PlatformFile? file;
  try {
    file = await FilePicker.pickFile(
      dialogTitle: dialogTitle,
      type: FileType.custom,
      allowedExtensions: _imageContentTypes.keys.toList(),
    );
  } catch (e) {
    debugPrint('Odabir slike nije uspio: $e');
    return const ImagePickResult.error('Odabir slike nije uspio.');
  }
  if (file == null) {
    return null;
  }

  final contentType = _imageContentTypes[file.extension?.toLowerCase()];
  if (contentType == null) {
    return const ImagePickResult.error('Dozvoljene su samo slike u formatu JPG ili PNG.');
  }
  final length = await file.length();
  if (length != null && length > _maxImageBytes) {
    return const ImagePickResult.error('Slika može imati najviše 2 MB.');
  }

  final bytes = await file.readAsBytes();
  if (bytes.isEmpty || bytes.length > _maxImageBytes) {
    return ImagePickResult.error(bytes.isEmpty ? 'Odabrani fajl je prazan.' : 'Slika može imati najviše 2 MB.');
  }
  return ImagePickResult.image(PickedImage(bytes: bytes, name: file.name, contentType: contentType));
}
