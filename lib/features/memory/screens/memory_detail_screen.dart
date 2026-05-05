import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/models/memory_model.dart';
import '../../../data/repositories/memory_repository.dart';
import '../../../shared/widgets/universal_image_provider.dart';

class MemoryDetailScreen extends StatefulWidget {
  final Memory memory;

  const MemoryDetailScreen({super.key, required this.memory});

  @override
  State<MemoryDetailScreen> createState() => _MemoryDetailScreenState();
}

class _MemoryDetailScreenState extends State<MemoryDetailScreen> {
  final repo = MemoryRepository();
  final picker = ImagePicker();

  String formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  final List<String> moods = ['Happy', 'Sad', 'Excited', 'Tired'];

  String getMoodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return '😊';
      case 'sad':
        return '😢';
      case 'excited':
        return '🤩';
      case 'tired':
        return '😴';
      default:
        final trimmed = mood.trim();
        if (trimmed.isEmpty) return '🙂';
        return String.fromCharCodes(trimmed.runes.take(1));
    }
  }

  String getMoodLabel(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return 'Happy';
      case 'sad':
        return 'Sad';
      case 'excited':
        return 'Excited';
      case 'tired':
        return 'Tired';
      default:
        return mood;
    }
  }

  Future<String> _resolveImagePath(XFile image) async {
    if (!kIsWeb) {
      return image.path;
    }

    final bytes = await image.readAsBytes();
    final mimeType = _mimeTypeFromFileName(image.name);
    final base64Data = base64Encode(bytes);
    return 'data:$mimeType;base64,$base64Data';
  }

  String _mimeTypeFromFileName(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'application/octet-stream';
  }

  // 🗑️ Delete
  void deleteMemory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Delete Memory',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,),
          ),
          content:  Text(
            'Are you sure you want to delete this memory? This action cannot be undone.',
            style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    // ❗ If user cancels → do nothing
    if (confirm != true) return;

    // ✅ Proceed delete
    await repo.deleteMemory(widget.memory.id);

    if (!mounted) return;

    Navigator.pop(context);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Memory deleted')));
  }

  // ✏️ Edit description, mood, and date
  void editMemory() async {
    final titleController = TextEditingController(text: widget.memory.title);
    final descriptionController = TextEditingController(text: widget.memory.description);
    String selectedMood = widget.memory.mood;
    DateTime selectedDate = widget.memory.date;
    final editedMediaPaths = List<String>.from(widget.memory.mediaPaths);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> addImageFromCamera() async {
              final picked = await picker.pickImage(source: ImageSource.camera);
              if (picked == null) return;

              final resolved = await _resolveImagePath(picked);
              setDialogState(() {
                editedMediaPaths.add(resolved);
              });
            }

            Future<void> addImagesFromGallery() async {
              final pickedFiles = await picker.pickMultiImage();
              if (pickedFiles.isEmpty) return;

              final addedPaths = <String>[];
              for (final image in pickedFiles) {
                addedPaths.add(await _resolveImagePath(image));
              }

              setDialogState(() {
                editedMediaPaths.addAll(addedPaths);
              });
            }

            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              title: Text(
                'Edit Memory',
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Mood'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: moods.map((mood) {
                        return ChoiceChip(
                          label: Text(getMoodLabel(mood)),
                          selected: selectedMood.toLowerCase() == mood.toLowerCase(),
                          onSelected: (_) {
                            setDialogState(() {
                              selectedMood = mood;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    const Text('Images'),
                    const SizedBox(height: 8),
                    if (editedMediaPaths.isNotEmpty)
                      SizedBox(
                        height: 100,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: List.generate(
                              editedMediaPaths.length,
                              (index) {
                                final path = editedMediaPaths[index];
                                return Padding(
                                  padding: EdgeInsets.only(right: index == editedMediaPaths.length - 1 ? 0 : 12),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image(
                                          image: universalImageProvider(path),
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: Container(
                                          width: 28,
                                          height: 28,
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: IconButton(
                                            padding: EdgeInsets.zero,
                                            iconSize: 18,
                                            onPressed: () {
                                              setDialogState(() {
                                                editedMediaPaths.removeAt(index);
                                              });
                                            },
                                            icon: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                        ),
                        child: const Text('No images attached'),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: addImagesFromGallery,
                            icon: const Icon(Icons.photo),
                            label: const Text('Gallery'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: addImageFromCamera,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Camera'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Date'),
                      subtitle: Text(formatDate(selectedDate)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    widget.memory.title = titleController.text.trim().isEmpty
                        ? widget.memory.title
                        : titleController.text.trim();
                    widget.memory.description = descriptionController.text.trim();
                    widget.memory.mood = selectedMood;
                    widget.memory.date = selectedDate;
                    widget.memory.mediaPaths = editedMediaPaths;

                    await repo.updateMemory(widget.memory);
                    setState(() {});
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final memory = widget.memory;
    final hasImage = memory.mediaPaths.isNotEmpty;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: const Text('Memory Detail'),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: editMemory),
          IconButton(icon: const Icon(Icons.delete), onPressed: deleteMemory),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (hasImage)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    Image(
                      image: universalImageProvider(memory.mediaPaths.first),
                      height: 260,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Container(
                      height: 260,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.45),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 20,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              memory.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            getMoodEmoji(memory.mood),
                            style: const TextStyle(fontSize: 26),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Text(
                              getMoodEmoji(memory.mood),
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              getMoodLabel(memory.mood),
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Date',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatDate(memory.date),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (memory.description.isNotEmpty) ...[
                    Text(
                      'Memory',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      memory.description,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
