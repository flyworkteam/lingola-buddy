import 'package:image_picker/image_picker.dart';

/// Profil fotoğrafı seçimi — yükleme [UserProfileApiService] üzerinden yapılır.
class ProfilePhotoService {
  ProfilePhotoService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<String?> pickImagePath(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    return picked?.path;
  }
}
