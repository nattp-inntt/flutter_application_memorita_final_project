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
  bool _isExporting = false;
  bool _isImporting = false;

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Settings',
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
        children: [
          // ── Appearance ──────────────────────────────────────────────
          _sectionTitle(context, 'Appearance'),
          _card(
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: ThemeService.themeMode,
              builder: (context, mode, child) {
                final isDark = mode == ThemeMode.dark;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: _iconBox(
                    isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                    isDark ? const Color(0xFFA78BFA) : const Color(0xFFFBBF24),
                  ),
                  title: const Text('Dark Mode'),
                  subtitle: Text(isDark ? 'Currently dark' : 'Currently light'),
                  trailing: Switch(
                    value: isDark,
                    onChanged: ThemeService.toggleTheme,
                    activeThumbColor: const Color(0xFF6C63FF),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // ── Data ────────────────────────────────────────────────────
          _sectionTitle(context, 'Data'),
          _card(
            child: Column(
              children: [
                // Export
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: _iconBox(
                    Icons.upload_outlined,
                    const Color(0xFF10B981),
                  ),
                  title: const Text('Export Memories'),
                  subtitle: const Text('Save as .json file with photos'),
                  trailing: _isExporting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          Icons.chevron_right,
                          color: Theme.of(context)
                              .iconTheme
                              .color
                              ?.withValues(alpha: 0.3),
                        ),
                  onTap: _isExporting ? null : exportMemories,
                ),

                Divider(
                  color: Theme.of(context)
                      .dividerColor
                      .withValues(alpha: 0.15),
                  height: 1,
                ),

                // Import
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: _iconBox(
                    Icons.download_outlined,
                    const Color(0xFF60A5FA),
                  ),
                  title: const Text('Import Memories'),
                  subtitle: const Text('Load from a .json export file'),
                  trailing: _isImporting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          Icons.chevron_right,
                          color: Theme.of(context)
                              .iconTheme
                              .color
                              ?.withValues(alpha: 0.3),
                        ),
                  onTap: _isImporting ? null : importMemories,
                ),

                Divider(
                  color: Theme.of(context)
                      .dividerColor
                      .withValues(alpha: 0.15),
                  height: 1,
                ),

                // Clear all
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: _iconBox(
                    Icons.delete_outline,
                    Colors.red,
                  ),
                  title: const Text(
                    'Clear All Data',
                    style: TextStyle(color: Colors.red),
                  ),
                  subtitle: const Text('Permanently delete all memories'),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: Theme.of(context)
                        .iconTheme
                        .color
                        ?.withValues(alpha: 0.3),
                  ),
                  onTap: showDeleteAllDialog,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── About ────────────────────────────────────────────────────
          _sectionTitle(context, 'About'),
          _card(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: _iconBox(
                    Icons.book_outlined,
                    const Color(0xFF6C63FF),
                  ),
                  title: const Text('Memorita'),
                  subtitle: const Text('Life Archive'),
                ),
                Divider(
                  color: Theme.of(context)
                      .dividerColor
                      .withValues(alpha: 0.15),
                  height: 1,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: _iconBox(
                    Icons.tag_outlined,
                    const Color(0xFF6EE7B7),
                  ),
                  title: const Text('Version'),
                  trailing: Text(
                    '1.0.3',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.color
                              ?.withValues(alpha: 0.5),
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── UI helpers ──────────────────────────────────────────────────────────────

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              letterSpacing: 0.6,
              color: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.color
                  ?.withValues(alpha: 0.5),
            ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.12),
        ),
      ),
      child: child,
    );
  }

  Widget _iconBox(IconData icon, Color color) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }

  // ── Delete all ──────────────────────────────────────────────────────────────

  void showDeleteAllDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete All Memories?'),
        content: const Text(
          'This will permanently delete every memory and cannot be undone. '
          'Consider exporting first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await Hive.box<Memory>('memories').clear();
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All memories deleted')),
              );
            },
            child: const Text(
              'Delete All',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ── Export ──────────────────────────────────────────────────────────────────

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No memories to export')),
      );
      return;
    }

    // ── Warn if large export ──────────────────────────────────────────
    final withImages =
        memories.where((m) => m.mediaPaths.isNotEmpty).length;
    if (withImages > 15) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: const Text('Large Export'),
          content: Text(
            'You have $withImages memories with photos. '
            'The export file may be large and take a moment to prepare.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    // ── Start export ──────────────────────────────────────────────────
    setState(() => _isExporting = true);

    try {
      final jsonData = <Map<String, dynamic>>[];
      int skippedImages = 0;

      for (final memory in memories) {
        final frozen = await _freezeMemoryWithMedia(memory);

        // Count how many images were successfully serialized
        final expected = memory.mediaPaths.length;
        final got = (frozen['mediaFiles'] as List?)?.length ?? 0;
        skippedImages += expected - got;

        jsonData.add(frozen);
      }

      final jsonString = jsonEncode(jsonData);
      await exportJsonString('memories.json', jsonString);

      if (!mounted) return;

      // ── Success feedback ──────────────────────────────────────────
      if (skippedImages > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Exported ${memories.length} memories. '
              '$skippedImages image(s) could not be found and were skipped.',
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Exported ${memories.length} memories successfully ✓'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export failed. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  // ── Import ──────────────────────────────────────────────────────────────────

  Future<void> importMemories() async {
    setState(() => _isImporting = true);

    try {
      // ── Pick file ───────────────────────────────────────────────────
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null) {
        setState(() => _isImporting = false);
        return;
      }

      // ── Read & parse ────────────────────────────────────────────────
      final jsonString = await readFileString(result.files.single);
      final List data = jsonDecode(jsonString);
      final box = Hive.box<Memory>('memories');

      int imported = 0;
      int skipped = 0;
      int failed = 0;

      for (var item in data) {
        try {
          // ── Duplicate check ───────────────────────────────────────
          final id = item['id'] ?? DateTime.now().toString();
          if (box.containsKey(id)) {
            skipped++;
            continue;
          }

          // ── Restore images ────────────────────────────────────────
          final mediaPaths = <String>[];
          final mediaFiles = item['mediaFiles'];

          if (mediaFiles != null) {
            // New format — restore from embedded base64
            for (final rawFile in List.from(mediaFiles)) {
              try {
                final fileName = rawFile['fileName']?.toString() ??
                    'imported_${DateTime.now().millisecondsSinceEpoch}.bin';
                final fileData = rawFile['data']?.toString();
                if (fileData == null || fileData.isEmpty) continue;

                final savedPath =
                    await saveBase64MediaFile(fileName, fileData);
                mediaPaths.add(savedPath);
              } catch (_) {
                continue; // skip individual broken image, don't fail whole entry
              }
            }
          } else {
            // Old format fallback — raw paths (images may not exist)
            mediaPaths.addAll(
                List<String>.from(item['mediaPaths'] ?? []));
          }

          // ── Build Memory object ───────────────────────────────────
          final memory = Memory(
            id: id,
            title: item['title'] ?? '',
            description: item['description'] ?? '',
            date: DateTime.parse(item['date']),
            mood: item['mood'] ?? 'Happy',
            mediaPaths: mediaPaths,
            tags: List<String>.from(item['tags'] ?? []),
            locationName: item['locationName'],
            lat: (item['lat'] as num?)?.toDouble(),
            lng: (item['lng'] as num?)?.toDouble(),
          );

          await box.put(memory.id, memory);
          imported++;
        } catch (_) {
          failed++; // malformed entry — skip and continue
        }
      }

      if (!mounted) return;

      // ── Result feedback ────────────────────────────────────────────
      final parts = <String>[];
      if (imported > 0) {
        parts.add('$imported imported');
      }
      if (skipped > 0) {
        parts.add('$skipped duplicate${skipped == 1 ? '' : 's'} skipped');
      }
      if (failed > 0) {
        parts.add('$failed failed');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(parts.isEmpty
              ? 'Nothing to import'
              : parts.join(' · ')),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to read file. Is it a valid export?')),
      );
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }
}