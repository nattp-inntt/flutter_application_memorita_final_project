import 'package:uuid/uuid.dart';
import '../../core/services/storage_service.dart';
import '../models/memory_model.dart';

class MemoryRepository {
  final box = StorageService.getMemoryBox();
  final uuid = const Uuid();

  // Create
  Future<void> addMemory(Memory memory) async {
    await box.put(memory.id, memory);
  }

  // Read all
  List<Memory> getAllMemories() {
    return box.values.toList();
  }

  // Delete
  Future<void> deleteMemory(String id) async {
    await box.delete(id);
  }

  // Update
  Future<void> updateMemory(Memory memory) async {
    await box.put(memory.id, memory);
  }

  // Generate ID helper
  String generateId() => uuid.v4();
}