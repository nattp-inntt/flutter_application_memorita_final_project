import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> exportJsonStringImpl(String fileName, String jsonString) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/$fileName');
  await file.writeAsString(jsonString);

  await Share.shareXFiles([XFile(file.path)], text: 'My Life Archive Memories');
}

Future<String> readFileStringImpl(PlatformFile file) async {
  if (file.path != null) {
    return File(file.path!).readAsString();
  }

  if (file.bytes != null) {
    return utf8.decode(file.bytes!);
  }

  throw Exception('Unable to read picked file');
}
