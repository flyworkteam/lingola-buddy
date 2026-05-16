import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:lingola_buddy/Services/profile_photo_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ProfilePhotoService {
  ProfilePhotoService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<String?> pickAndPersist({
    required ImageSource source,
    String? previousPath,
  }) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (picked == null) return null;

    final localPath = await _copyToProfileDir(picked.path);
    if (previousPath != null && previousPath != localPath) {
      try {
        final old = File(previousPath);
        if (await old.exists()) await old.delete();
      } catch (_) {}
    }

    await ProfilePhotoStorage.savePath(localPath);
    return localPath;
  }

  Future<void> removeStoredPhoto(String? currentPath) async {
    await ProfilePhotoStorage.clear(pathToDelete: currentPath);
  }

  Future<String> _copyToProfileDir(String sourcePath) async {
    final dir = await getApplicationDocumentsDirectory();
    final profileDir = Directory(p.join(dir.path, 'profile'));
    if (!await profileDir.exists()) {
      await profileDir.create(recursive: true);
    }

    final ext = p.extension(sourcePath).isEmpty ? '.jpg' : p.extension(sourcePath);
    final destPath = p.join(
      profileDir.path,
      'avatar_${DateTime.now().millisecondsSinceEpoch}$ext',
    );
    await File(sourcePath).copy(destPath);
    return destPath;
  }
}
