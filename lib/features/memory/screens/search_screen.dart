import 'package:flutter/material.dart';
import '../../../data/models/memory_model.dart';
import '../../../data/repositories/memory_repository.dart';
import '../../../routes/app_routes.dart';
import '../widgets/memory_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final repo = MemoryRepository();

  List<Memory> allMemories = [];
  List<Memory> filteredMemories = [];

  @override
  void initState() {
    super.initState();
    loadMemories();
  }

  void loadMemories() {
    final data = repo.getAllMemories();

    setState(() {
      allMemories = data;
      filteredMemories = data; // initially show all
    });
  }

  void search(String query) {
    final results = allMemories.where((memory) {
      final title = memory.title.toLowerCase();
      final desc = memory.description.toLowerCase();
      final tags = memory.tags.join(' ').toLowerCase();

      return title.contains(query) ||
          desc.contains(query) ||
          tags.contains(query);
    }).toList();

    setState(() {
      filteredMemories = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Memories')),
      body: Column(
        children: [
          // 🔍 Search Field
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: search,
              decoration: InputDecoration(
                hintText: 'Search memories...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      filteredMemories = allMemories;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // 📜 Results
          Expanded(
            child: filteredMemories.isEmpty
                ? const Center(child: Text('No results found'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filteredMemories.length,
                    itemBuilder: (context, index) {
                      final memory = filteredMemories[index];
                      return MemoryCard(
                        memory: memory,
                        onTap: () async {
                          await Navigator.pushNamed(
                            context,
                            AppRoutes.memoryDetail,
                            arguments: memory,
                          );
                          loadMemories();
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
