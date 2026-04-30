import 'package:flutter/widgets.dart';

ImageProvider<Object> getUniversalImageProvider(String path) {
  return NetworkImage(path);
}
