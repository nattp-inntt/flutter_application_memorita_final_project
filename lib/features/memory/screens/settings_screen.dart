import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hive/hive.dart';

import '../../../data/models/memory_model.dart';
import '../../../core/services/theme_service.dart';
import '../../../core/utils/settings_file_utils.dart';
import '../../../core/utils/media_file_utils.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 🧠 GENERAL
          _sectionTitle("General"),
          _card(
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: ThemeService.themeMode,
              builder: (context, mode, child) {
                return SwitchListTile(
                  title: const Text("Dark Mode"),
                  value: mode == ThemeMode.dark,
                  onChanged: (value) {
                    ThemeService.toggleTheme(value);
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // 💾 DATA
          _sectionTitle("Data"),
          _card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text("Import Memories"),
                  onTap: importMemories,
                ),
                ListTile(
                  leading: const Icon(Icons.upload),
                  title: const Text("Export Memories"),
                  onTap: exportMemories,
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text("Clear All Data"),
                  onTap: showDeleteAllDialog,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ℹ️ ABOUT
          _sectionTitle("About"),
          _card(
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Memorita - Life Archive"),
                SizedBox(height: 4),
                Text("Version 0.9.9"),
                SizedBox(height: 4),
                Text("Developed by Memorita Team"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🧱 UI Helpers
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  // 🚨 Confirm delete
  void showDeleteAllDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete All Memories?"),
        content: const Text("This action cannot be undone. Are you sure?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await clearAllMemories();
              if (!mounted) return;

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("All memories deleted")),
              );
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Future<void> clearAllMemories() async {
    final box = Hive.box<Memory>('memories');
    await box.clear();
  }

  Future<Map<String, dynamic>> _freezeMemoryWithMedia(Memory memory) async {
    final json = memory.toJson();
    final mediaFiles = <Map<String, dynamic>>[];

    for (final mediaPath in memory.mediaPaths) {
      final mediaEntry = await serializeMediaPath(mediaPath);
      if (mediaEntry != null) {
        mediaFiles.add(mediaEntry);
      }
    }

    if (mediaFiles.isNotEmpty) {
      json['mediaFiles'] = mediaFiles;
    }

    return json;
  }

  Future<void> exportMemories() async {
    final box = Hive.box<Memory>('memories');

    final memories = box.values.toList();

    if (memories.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No memories to export")));
      return;
    }

    // Convert each memory to JSON and embed image bytes.
    final jsonData = <Map<String, dynamic>>[];
    for (final memory in memories) {
      jsonData.add(await _freezeMemoryWithMedia(memory));
    }

    final jsonString = jsonEncode(jsonData);
    await exportJsonString('memories.json', jsonString);
  }

  Future<void> importMemories() async {
    try {
      // 📂 Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null) return;

      // 📖 Read file
      final jsonString = await readFileString(result.files.single);
      final List data = jsonDecode(jsonString);

      final box = Hive.box<Memory>('memories');

      // 🔄 Convert JSON → Memory objects
      for (var item in data) {
        final mediaPaths = <String>[];
        final mediaFiles = item['mediaFiles'];

        if (mediaFiles != null) {
          for (final rawFile in List.from(mediaFiles)) {
            try {
              final fileName =
                  rawFile['fileName']?.toString() ??
                  'imported_${DateTime.now().millisecondsSinceEpoch}.bin';
              final fileData = rawFile['data']?.toString();
              if (fileData == null || fileData.isEmpty) continue;

              final savedPath = await saveBase64MediaFile(fileName, fileData);
              mediaPaths.add(savedPath);
            } catch (_) {
              continue;
            }
          }
        } else {
          mediaPaths.addAll(List<String>.from(item['mediaPaths'] ?? []));
        }

        final memory = Memory(
          id: item['id'] ?? DateTime.now().toString(),
          title: item['title'] ?? '',
          description: item['description'] ?? '',
          date: DateTime.parse(item['date']),
          mood: item['mood'] ?? 'Neutral',
          mediaPaths: mediaPaths,
          tags: List<String>.from(item['tags'] ?? []),
          locationName: item['locationName'],
          lat: item['lat'],
          lng: item['lng'],
        );

        await box.put(memory.id, memory);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Import successful")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to import file")));
    }
  }
}
