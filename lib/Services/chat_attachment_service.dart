import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lingola_buddy/Models/chat_attachment_model.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ChatAttachmentPickResult {
  const ChatAttachmentPickResult({
    required this.kind,
    required this.localPath,
    required this.displayName,
  });

  final ChatAttachmentKind kind;
  final String localPath;
  final String displayName;
}

class ChatAttachmentService {
  ChatAttachmentService({ImagePicker? imagePicker})
      : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  static const _documentExtensions = [
    'pdf',
    'doc',
    'docx',
    'txt',
    'ppt',
    'pptx',
    'xls',
    'xlsx',
    'rtf',
    'csv',
  ];

  Future<ChatAttachmentPickResult?> pickImageFromGallery() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
    );
    if (picked == null) return null;

    final name = p.basename(picked.path);
    final localPath = await _persistFile(picked.path, name);
    return ChatAttachmentPickResult(
      kind: ChatAttachmentKind.image,
      localPath: localPath,
      displayName: name,
    );
  }

  Future<ChatAttachmentPickResult?> pickDocument() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: _documentExtensions,
      allowMultiple: false,
      withData: false,
    );

    if (result == null || result.files.isEmpty) return null;
    final file = result.files.single;
    final path = file.path;
    if (path == null || path.isEmpty) return null;

    final name = file.name.isNotEmpty ? file.name : p.basename(path);
    final localPath = await _persistFile(path, name);
    return ChatAttachmentPickResult(
      kind: ChatAttachmentKind.document,
      localPath: localPath,
      displayName: name,
    );
  }

  Future<String> _persistFile(String sourcePath, String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final attachmentsDir = Directory(p.join(dir.path, 'chat_attachments'));
    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }

    final safeName = fileName.replaceAll(RegExp(r'[^\w.\-]'), '_');
    final destPath = p.join(
      attachmentsDir.path,
      '${DateTime.now().millisecondsSinceEpoch}_$safeName',
    );
    await File(sourcePath).copy(destPath);
    return destPath;
  }
}
