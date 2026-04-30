import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<Map<String, dynamic>?> serializeMediaPathImpl(String mediaPath) async {
  final file = File(mediaPath);
  if (!await file.exists()) return null;

  final bytes = await file.readAsBytes();
  final fileName = file.uri.pathSegments.isNotEmpty
      ? file.uri.pathSegments.last
      : 'media_${DateTime.now().millisecondsSinceEpoch}.bin';

  return {
    'fileName': fileName,
    'mimeType': _mimeTypeFromFileName(fileName),
    'data': base64Encode(bytes),
  };
}

Future<String> saveBase64MediaFileImpl(
  String fileName,
  String base64Data,
) async {
  final directory = await getApplicationDocumentsDirectory();
  final mediaDirectory = Directory('${directory.path}/imported_media');
  if (!await mediaDirectory.exists()) {
    await mediaDirectory.create(recursive: true);
  }

  final safeName = _sanitizeFileName(fileName);
  final target = File(
    '${mediaDirectory.path}/${DateTime.now().millisecondsSinceEpoch}_$safeName',
  );
  await target.writeAsBytes(base64Decode(base64Data));

  return target.path;
}

String _mimeTypeFromFileName(String fileName) {
  final lower = fileName.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  if (lower.endsWith('.gif')) return 'image/gif';
  return 'application/octet-stream';
}

String _sanitizeFileName(String fileName) {
  return fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
}
