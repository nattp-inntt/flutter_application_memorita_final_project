import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/memory_model.dart';

class StorageService {
  static const String memoryBoxName = 'memories';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register adapter
    Hive.registerAdapter(MemoryAdapter());

    // Open box
    await Hive.openBox<Memory>(memoryBoxName);
  }

  static Box<Memory> getMemoryBox() {
    return Hive.box<Memory>(memoryBoxName);
  }
}