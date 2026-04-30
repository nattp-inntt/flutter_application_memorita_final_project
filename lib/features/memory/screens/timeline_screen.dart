// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../../data/models/memory_model.dart';
import '../../../data/repositories/memory_repository.dart';
import '../widgets/memory_card.dart';
import '../../../routes/app_routes.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final repo = MemoryRepository();
  String sortOrder = 'Newest';
  String selectedMood = "All";

  Map<String, List<Memory>> groupedMemories = {};

  @override
  void initState() {
    super.initState();
    loadMemories();
  }

  void loadMemories() {
    final data = repo.getAllMemories();

    // 😊 FILTER
    List<Memory> filtered = selectedMood == "All"
        ? data
        : data.where((m) => m.mood == selectedMood).toList();

    // 🔽 SORT
    filtered.sort((a, b) => sortOrder == "Newest"
        ? b.date.compareTo(a.date)
        : a.date.compareTo(b.date));

    groupedMemories = groupByDate(filtered);

    setState(() {});
  }

  void openFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        String tempSort = sortOrder;
        String tempMood = selectedMood;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Text("Filter & Sort",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

                  const SizedBox(height: 16),

                  // 🔽 SORT
                  const Text("Sort Order"),
                  DropdownButton<String>(
                    value: tempSort,
                    isExpanded: true,
                    items: ["Newest", "Oldest"]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (value) {
                      setModalState(() {
                        tempSort = value!;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // 😊 MOOD FILTER
                  const Text("Mood"),
                  DropdownButton<String>(
                    value: tempMood,
                    isExpanded: true,
                    items: ["All", "Happy", "Sad", "Excited", "Tired"]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (value) {
                      setModalState(() {
                        tempMood = value!;
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  // ✅ APPLY BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          sortOrder = tempSort;
                          selectedMood = tempMood;
                        });

                        loadMemories();

                        Navigator.pop(context);
                      },
                      child: const Text("Apply"),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 🧠 Group Logic
  Map<String, List<Memory>> groupByDate(List<Memory> memories) {
    Map<String, List<Memory>> grouped = {};

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (var memory in memories) {
      final memoryDate = DateTime(
        memory.date.year,
        memory.date.month,
        memory.date.day,
      );

      String key;

      if (memoryDate == today) {
        key = "Today";
      } else if (memoryDate == yesterday) {
        key = "Yesterday";
      } else {
        key = "${memory.date.day}/${memory.date.month}/${memory.date.year}";
      }

      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }

      grouped[key]!.add(memory);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Timeline"),
        leading: IconButton(
          icon: const Icon(Icons.tune),
          tooltip: 'Filter & Sort',
          onPressed: openFilterSheet,
        ),
      ),

      body: groupedMemories.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_album,
                    size: 80,
                    color: Theme.of(context).iconTheme.color?.withOpacity(0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No memories yet",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    "Start capturing your moments ✨",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(12),
              children: groupedMemories.entries.map((entry) {
                final title = entry.key;
                final memories = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 📅 Section Title
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // 📦 Memory List
                    ...memories.map(
                      (memory) => Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              CircleAvatar(
                                radius: 4,
                                backgroundColor: Theme.of(context).dividerColor,
                              ),
                              Container(
                                width: 2,
                                height: 80, // adjust based on card size
                                color: Theme.of(context).dividerColor,
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: MemoryCard(
                              memory: memory,
                              onTap: () async {
                                await Navigator.pushNamed(
                                  context,
                                  AppRoutes.memoryDetail,
                                  arguments: memory,
                                );
                                loadMemories();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),
                  ],
                );
              }).toList(),
            ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(context, AppRoutes.addMemory);
          loadMemories(); // 🔄 refresh
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class FeatureCard extends StatelessWidget {
  final String title;

  const FeatureCard({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(title, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

class CategoryCard extends StatelessWidget {
  final String title;

  const CategoryCard({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withOpacity(0.85),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const Icon(Icons.arrow_forward),
        ],
      ),
    );
  }
}

class CategorySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Your Memories",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: const [
              CategoryCard(title: "Travel"),
              CategoryCard(title: "Family"),
              CategoryCard(title: "Work"),
              CategoryCard(title: "Feelings"),
            ],
          ),
        ],
      ),
    );
  }
}
