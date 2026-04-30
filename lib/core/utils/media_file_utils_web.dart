import 'dart:convert';

Future<Map<String, dynamic>?> serializeMediaPathImpl(String mediaPath) async {
  if (mediaPath.startsWith('data:')) {
    final uri = Uri.parse(mediaPath);
    final uriData = uri.data;
    if (uriData == null) return null;

    final mimeType = uriData.mimeType.isNotEmpty
        ? uriData.mimeType
        : 'application/octet-stream';
    final fileName = 'imported_${DateTime.now().millisecondsSinceEpoch}${_extensionFromMimeType(mimeType)}';

    return {
      'fileName': fileName,
      'mimeType': mimeType,
      'data': base64Encode(uriData.contentAsBytes()),
    };
  }

  return null;
}

Future<String> saveBase64MediaFileImpl(
  String fileName,
  String base64Data,
) async {
  final mimeType = _mimeTypeFromFileName(fileName);
  return 'data:$mimeType;base64,$base64Data';
}

String _mimeTypeFromFileName(String fileName) {
  final lower = fileName.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  if (lower.endsWith('.gif')) return 'image/gif';
  return 'application/octet-stream';
}

String _extensionFromMimeType(String mimeType) {
  if (mimeType == 'image/png') return '.png';
  if (mimeType == 'image/jpeg') return '.jpg';
  if (mimeType == 'image/gif') return '.gif';
  return '.bin';
}
