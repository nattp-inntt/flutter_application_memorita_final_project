import 'media_file_utils_io.dart'
    if (dart.library.html) 'media_file_utils_web.dart';

Future<Map<String, dynamic>?> serializeMediaPath(String mediaPath) =>
    serializeMediaPathImpl(mediaPath);

Future<String> saveBase64MediaFile(String fileName, String base64Data) =>
    saveBase64MediaFileImpl(fileName, base64Data);
