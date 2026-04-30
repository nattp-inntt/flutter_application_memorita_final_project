import 'package:flutter/widgets.dart';

import 'universal_image_provider_io.dart'
    if (dart.library.html) 'universal_image_provider_web.dart';

ImageProvider<Object> universalImageProvider(String path) =>
    getUniversalImageProvider(path);
