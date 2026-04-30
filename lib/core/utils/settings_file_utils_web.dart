import 'dart:convert';
import 'dart:html' as html;

import 'package:file_picker/file_picker.dart';

Future<void> exportJsonStringImpl(String fileName, String jsonString) async {
  final bytes = utf8.encode(jsonString);
  final blob = html.Blob([bytes], 'application/json');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.document.createElement('a') as html.AnchorElement;
  anchor.href = url;
  anchor.download = fileName;
  anchor.style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}

Future<String> readFileStringImpl(PlatformFile file) async {
  if (file.bytes != null) {
    return utf8.decode(file.bytes!);
  }

  throw Exception('Unable to read picked file');
}
