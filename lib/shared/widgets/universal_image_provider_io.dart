import 'dart:io';
import 'package:flutter/widgets.dart';

ImageProvider<Object> getUniversalImageProvider(String path) {
  return FileImage(File(path));
}
