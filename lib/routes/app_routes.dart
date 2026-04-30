import 'package:flutter/material.dart';
//import '../features/memory/screens/home_screen.dart';
import '../features/memory/screens/add_memory_screen.dart';
import '../features/memory/screens/memory_detail_screen.dart';
import '../features/memory/screens/search_screen.dart';
import '../data/models/memory_model.dart';

class AppRoutes {
  // Route names
  static const String home = '/';
  static const String addMemory = '/add-memory';
  static const String memoryDetail = '/memory-detail';
  static const String search = '/search';

  // Route map
  static Map<String, WidgetBuilder> get routes => {
        '/add-memory': (context) => const AddMemoryScreen(),
        '/search': (context) => const SearchScreen(),
        '/memory-detail': (context) {
          final memory = ModalRoute.of(context)!.settings.arguments as Memory;
          return MemoryDetailScreen(memory: memory);
        },
      };
}