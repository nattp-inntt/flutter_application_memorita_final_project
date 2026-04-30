import 'package:file_picker/file_picker.dart';

import 'settings_file_utils_io.dart'
    if (dart.library.html) 'settings_file_utils_web.dart';

Future<void> exportJsonString(String fileName, String jsonString) =>
    exportJsonStringImpl(fileName, jsonString);

Future<String> readFileString(PlatformFile file) => readFileStringImpl(file);
