import 'package:image_picker/image_picker.dart';

import 'image_gateway.dart';

/// [ImageGateway] com o `image_picker` (seletor de fotos do Android, sem
/// permissão de armazenamento).
class ImagePickerGateway implements ImageGateway {
  ImagePickerGateway([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Capas não precisam de mais que isso; evita copiar fotos de 12 MP.
  static const _maxSide = 1200.0;

  @override
  Future<String?> pickImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: _maxSide,
      maxHeight: _maxSide,
      imageQuality: 90,
    );
    return file?.path;
  }
}
