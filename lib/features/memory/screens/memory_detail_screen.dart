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

  // Image carousel state
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ── Formatters ─────────────────────────────────────────────────────────────

  String formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String getMoodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':   return '😊';
      case 'sad':     return '😢';
      case 'excited': return '🤩';
      case 'tired':   return '😴';
      default:
        final trimmed = mood.trim();
        if (trimmed.isEmpty) return '🙂';
        return String.fromCharCodes(trimmed.runes.take(1));
    }
  }

  String getMoodLabel(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':   return 'Happy';
      case 'sad':     return 'Sad';
      case 'excited': return 'Excited';
      case 'tired':   return 'Tired';
      default:        return mood;
    }
  }

  Color getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':   return const Color(0xFFFBBF24); // amber
      case 'sad':     return const Color(0xFF60A5FA); // blue
      case 'excited': return const Color(0xFFF97316); // orange
      case 'tired':   return const Color(0xFFA78BFA); // purple
      default:        return Colors.grey;
    }
  }

  // ── Image path resolver ────────────────────────────────────────────────────

  Future<String> _resolveImagePath(XFile image) async {
    if (!kIsWeb) return image.path;
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

  // ── Delete ─────────────────────────────────────────────────────────────────

  void deleteMemory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Memory',
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        content: Text(
          'Are you sure you want to delete this memory? This action cannot be undone.',
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await repo.deleteMemory(widget.memory.id);
    if (!mounted) return;

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Memory deleted')),
    );
  }

  // ── Edit ───────────────────────────────────────────────────────────────────

  final List<String> moods = ['Happy', 'Sad', 'Excited', 'Tired'];

  void editMemory() async {
    final titleController = TextEditingController(text: widget.memory.title);
    final descriptionController =
        TextEditingController(text: widget.memory.description);
    String selectedMood = widget.memory.mood;
    DateTime selectedDate = widget.memory.date;
    final editedMediaPaths = List<String>.from(widget.memory.mediaPaths);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> addImageFromCamera() async {
            final picked =
                await picker.pickImage(source: ImageSource.camera);
            if (picked == null) return;
            final resolved = await _resolveImagePath(picked);
            setDialogState(() => editedMediaPaths.add(resolved));
          }

          Future<void> addImagesFromGallery() async {
            final pickedFiles = await picker.pickMultiImage();
            if (pickedFiles.isEmpty) return;
            final paths = <String>[];
            for (final img in pickedFiles) {
              paths.add(await _resolveImagePath(img));
            }
            setDialogState(() => editedMediaPaths.addAll(paths));
          }

          String _formatShort(DateTime d) =>
              '${d.day}/${d.month}/${d.year}';

          return AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Edit Memory',
              style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color),
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
                        selected: selectedMood.toLowerCase() ==
                            mood.toLowerCase(),
                        onSelected: (_) =>
                            setDialogState(() => selectedMood = mood),
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
                                padding: EdgeInsets.only(
                                    right: index ==
                                            editedMediaPaths.length - 1
                                        ? 0
                                        : 12),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(16),
                                      child: Image(
                                        image:
                                            universalImageProvider(path),
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () => setDialogState(() =>
                                            editedMediaPaths
                                                .removeAt(index)),
                                        child: Container(
                                          width: 24,
                                          height: 24,
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 14,
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
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .cardColor
                            .withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.2)),
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
                    subtitle: Text(_formatShort(selectedDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
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
                  widget.memory.title =
                      titleController.text.trim().isEmpty
                          ? widget.memory.title
                          : titleController.text.trim();
                  widget.memory.description =
                      descriptionController.text.trim();
                  widget.memory.mood = selectedMood;
                  widget.memory.date = selectedDate;
                  widget.memory.mediaPaths = editedMediaPaths;

                  await repo.updateMemory(widget.memory);
                  setState(() {
                    // Reset carousel index if images changed
                    _currentImageIndex = 0;
                  });
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final memory = widget.memory;
    final hasImage = memory.mediaPaths.isNotEmpty;
    final moodColor = getMoodColor(memory.mood);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: const Text('Memory Detail'),
        actions: [
          IconButton(
              icon: const Icon(Icons.edit), onPressed: editMemory),
          IconButton(
              icon: const Icon(Icons.delete), onPressed: deleteMemory),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          // ── Image Carousel ──────────────────────────────────────────
          if (hasImage) _buildImageCarousel(memory, moodColor),

          // ── Info Card ───────────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title (shown here if no image)
                  if (!hasImage) ...[
                    Text(
                      memory.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Mood badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: moodColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                          color: moodColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(getMoodEmoji(memory.mood),
                            style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(
                          getMoodLabel(memory.mood),
                          style: TextStyle(
                            color: moodColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  _divider(),
                  const SizedBox(height: 20),

                  // Date row
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 16,
                          color: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.color
                              ?.withValues(alpha: 0.5)),
                      const SizedBox(width: 8),
                      Text(
                        formatDate(memory.date),
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontSize: 15),
                      ),
                    ],
                  ),

                  // Description
                  if (memory.description.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _divider(),
                    const SizedBox(height: 20),
                    Text(
                      'Memory',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withValues(alpha: 0.5),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      memory.description,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                            fontSize: 16,
                            height: 1.6,
                          ),
                    ),
                  ],

                  // Thumbnail strip for multiple images
                  if (memory.mediaPaths.length > 1) ...[
                    const SizedBox(height: 20),
                    _divider(),
                    const SizedBox(height: 16),
                    Text(
                      'Photos  (${memory.mediaPaths.length})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withValues(alpha: 0.5),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildThumbnailStrip(memory),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Image carousel with dot indicators ────────────────────────────────────

  Widget _buildImageCarousel(Memory memory, Color moodColor) {
    final count = memory.mediaPaths.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Swipeable pages
            SizedBox(
              height: 280,
              child: PageView.builder(
                controller: _pageController,
                itemCount: count,
                onPageChanged: (index) =>
                    setState(() => _currentImageIndex = index),
                itemBuilder: (context, index) {
                  return Image(
                    image: universalImageProvider(
                        memory.mediaPaths[index]),
                    height: 280,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),

            // Gradient overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.55),
                    ],
                    stops: const [0.45, 1.0],
                  ),
                ),
              ),
            ),

            // Title + mood at bottom
            Positioned(
              left: 20,
              right: 20,
              bottom: 16,
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
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(getMoodEmoji(memory.mood),
                      style: const TextStyle(fontSize: 26)),
                ],
              ),
            ),

            // Dot indicators (only if multiple images)
            if (count > 1)
              Positioned(
                top: 14,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(count, (index) {
                    final isActive = index == _currentImageIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin:
                          const EdgeInsets.symmetric(horizontal: 3),
                      width: isActive ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),

            // Image counter badge top-right
            if (count > 1)
              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentImageIndex + 1} / $count',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Thumbnail strip ────────────────────────────────────────────────────────

  Widget _buildThumbnailStrip(Memory memory) {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: memory.mediaPaths.length,
        itemBuilder: (context, index) {
          final isSelected = index == _currentImageIndex;
          return GestureDetector(
            onTap: () {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image(
                  image: universalImageProvider(
                      memory.mediaPaths[index]),
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Divider ────────────────────────────────────────────────────────────────

  Widget _divider() => Divider(
        height: 1,
        color: Theme.of(context)
            .dividerColor
            .withValues(alpha: 0.15),
      );
}