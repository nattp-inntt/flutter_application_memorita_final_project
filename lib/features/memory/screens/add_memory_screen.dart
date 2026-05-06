import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/memory_model.dart';
import '../../../data/repositories/memory_repository.dart';
import 'package:image_picker/image_picker.dart';

class AddMemoryScreen extends StatefulWidget {
  const AddMemoryScreen({super.key});

  @override
  State<AddMemoryScreen> createState() => _AddMemoryScreenState();
}

class _AddMemoryScreenState extends State<AddMemoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final ImagePicker picker = ImagePicker();

  List<XFile> selectedImages = [];
  String selectedMood = 'Happy';
  String customMoodName = 'Custom';
  String customMoodEmoji = '✨';
  DateTime selectedDate = DateTime.now();
  final repo = MemoryRepository();

  final List<String> moods = ['Happy', 'Sad', 'Excited', 'Tired', 'custom'];

  // ── Mood helpers ─────────────────────────────────────────────────────────────

  String getMoodEmoji(String mood) {
    switch (mood) {
      case 'Happy':   return '😊';
      case 'Sad':     return '😢';
      case 'Excited': return '🤩';
      case 'Tired':   return '😴';
      case 'custom':  return customMoodEmoji;
      default:
        final trimmed = mood.trim();
        return trimmed.isEmpty ? '✨' : String.fromCharCodes(trimmed.runes.take(1));
    }
  }

  String getMoodLabel(String mood) {
    switch (mood) {
      case 'Happy':   return 'Happy';
      case 'Sad':     return 'Sad';
      case 'Excited': return 'Excited';
      case 'Tired':   return 'Tired';
      case 'custom':  return customMoodName;
      default:
        final parts = mood.split(' ');
        return parts.length > 1 ? parts.sublist(1).join(' ') : mood;
    }
  }

  Color getMoodColor(String mood) {
    switch (mood) {
      case 'Happy':   return const Color(0xFFFBBF24);
      case 'Sad':     return const Color(0xFF60A5FA);
      case 'Excited': return const Color(0xFFF97316);
      case 'Tired':   return const Color(0xFFA78BFA);
      default:        return const Color(0xFF6EE7B7);
    }
  }

  String getStoredMood() => selectedMood == 'custom'
      ? '$customMoodEmoji $customMoodName'
      : selectedMood;

  // ── Image helpers ─────────────────────────────────────────────────────────────

  Future<void> pickFromCamera() async {
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked != null) setState(() => selectedImages.add(picked));
  }

  Future<void> pickImagesFromGallery() async {
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() => selectedImages.addAll(pickedFiles));
    }
  }

  void showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF1E1E2E),
                  child: Icon(Icons.camera_alt, color: Colors.white70),
                ),
                title: const Text('Take Photo'),
                subtitle: const Text('Use your camera'),
                onTap: () { Navigator.pop(context); pickFromCamera(); },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF1E1E2E),
                  child: Icon(Icons.photo_library, color: Colors.white70),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Select multiple photos'),
                onTap: () { Navigator.pop(context); pickImagesFromGallery(); },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String> _resolveImagePath(XFile image) async {
    if (!kIsWeb) return image.path;
    final bytes = await image.readAsBytes();
    final mimeType = _mimeTypeFromFileName(image.name);
    return 'data:$mimeType;base64,${base64Encode(bytes)}';
  }

  String _mimeTypeFromFileName(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'application/octet-stream';
  }

  Widget _buildPreviewImage(XFile image) {
    return FutureBuilder<Uint8List>(
      future: image.readAsBytes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        final bytes = snapshot.data;
        if (bytes == null || bytes.isEmpty) return const SizedBox();
        return Image.memory(bytes, fit: BoxFit.cover,
            width: double.infinity, height: double.infinity);
      },
    );
  }

  // ── Custom mood dialog ────────────────────────────────────────────────────────

  Future<void> showCustomMoodDialog() async {
    final controller = TextEditingController(text: customMoodName);
    String tempEmoji = customMoodEmoji;
    const emojiOptions = [
      '😊', '😢', '🤩', '😴', '😎', '✨', '😍', '😌', '🥰',
      '😤', '🥳', '😔', '🤔', '😅', '🙃',
    ];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, dialogSetState) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: const Text('Custom Mood'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Mood name',
                  hintText: 'e.g. Grateful, Anxious...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Choose an emoji',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: emojiOptions.map((emoji) {
                  final isSelected = emoji == tempEmoji;
                  return GestureDetector(
                    onTap: () =>
                        dialogSetState(() => tempEmoji = emoji),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context)
                                .primaryColor
                                .withValues(alpha: 0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(emoji,
                            style: const TextStyle(fontSize: 22)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isEmpty) return;
                Navigator.pop(context, true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;
    setState(() {
      customMoodName = controller.text.trim().isEmpty
          ? customMoodName
          : controller.text.trim();
      customMoodEmoji = tempEmoji;
      selectedMood = 'custom';
    });
  }

  // ── Date picker ───────────────────────────────────────────────────────────────

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  // ── Save ──────────────────────────────────────────────────────────────────────

  Future<void> saveMemory() async {
    if (!_formKey.currentState!.validate()) return;

    final mediaPaths = <String>[];
    for (final image in selectedImages) {
      mediaPaths.add(await _resolveImagePath(image));
    }

    await repo.addMemory(Memory(
      id: DateTime.now().toString(),
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      date: selectedDate,
      mood: getStoredMood(),
      mediaPaths: mediaPaths,
      tags: [],
    ));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Memory saved! ✨')),
    );
    Navigator.pop(context);
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final moodColor = getMoodColor(selectedMood);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'New Memory',
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: saveMemory,
              style: TextButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 8),
              ),
              child: const Text('Save',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Photos section ──────────────────────────────────────
              _sectionLabel(context, 'Photos', Icons.photo_library_outlined),
              const SizedBox(height: 10),
              _buildPhotoGrid(theme),

              const SizedBox(height: 20),

              // ── Title & Description ─────────────────────────────────
              _sectionLabel(context, 'Memory', Icons.edit_outlined),
              const SizedBox(height: 10),
              _card(
                child: Column(
                  children: [
                    TextFormField(
                      controller: titleController,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: 'Give this memory a title...',
                        hintStyle: TextStyle(
                          color: theme.textTheme.bodySmall?.color
                              ?.withValues(alpha: 0.4),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'Please enter a title'
                          : null,
                    ),
                    Divider(
                        color:
                            theme.dividerColor.withValues(alpha: 0.2)),
                    TextFormField(
                      controller: descriptionController,
                      maxLines: 5,
                      style: theme.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText:
                            'What happened? How did it feel? Write as much as you want...',
                        hintStyle: TextStyle(
                          color: theme.textTheme.bodySmall?.color
                              ?.withValues(alpha: 0.4),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Mood selector ───────────────────────────────────────
              _sectionLabel(context, 'How are you feeling?',
                  Icons.emoji_emotions_outlined),
              const SizedBox(height: 10),
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Selected mood preview
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: moodColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: moodColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(getMoodEmoji(selectedMood),
                              style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 10),
                          Text(
                            getMoodLabel(selectedMood),
                            style: TextStyle(
                              color: moodColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Mood chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: moods.map((mood) {
                        final isSelected = selectedMood == mood;
                        final color = getMoodColor(mood);

                        return GestureDetector(
                          onTap: () {
                            if (mood == 'custom') {
                              showCustomMoodDialog();
                            } else {
                              setState(() => selectedMood = mood);
                            }
                          },
                          child: AnimatedContainer(
                            duration:
                                const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? color.withValues(alpha: 0.15)
                                  : theme.cardColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? color.withValues(alpha: 0.5)
                                    : theme.dividerColor
                                        .withValues(alpha: 0.2),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Text(
                              '${getMoodEmoji(mood)}  ${getMoodLabel(mood)}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected ? color : null,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Date picker ─────────────────────────────────────────
              _sectionLabel(context, 'Date', Icons.calendar_today_outlined),
              const SizedBox(height: 10),
              _card(
                child: InkWell(
                  onTap: pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.primaryColor
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.calendar_month,
                            color: theme.primaryColor, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE').format(selectedDate),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withValues(alpha: 0.5),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            DateFormat('MMMM d, yyyy')
                                .format(selectedDate),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Icon(Icons.chevron_right,
                          color: theme.iconTheme.color
                              ?.withValues(alpha: 0.4)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Photo grid ────────────────────────────────────────────────────────────────

  Widget _buildPhotoGrid(ThemeData theme) {
    // Empty state — big tap area
    if (selectedImages.isEmpty) {
      return GestureDetector(
        onTap: showImageSourcePicker,
        child: Container(
          height: 130,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.2),
              style: BorderStyle.solid,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_photo_alternate_outlined,
                    size: 36,
                    color: theme.textTheme.bodySmall?.color
                        ?.withValues(alpha: 0.4)),
                const SizedBox(height: 8),
                Text(
                  'Add photos',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodySmall?.color
                        ?.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tap to choose from gallery or camera',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color
                        ?.withValues(alpha: 0.35),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Grid with images + add button
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: selectedImages.length + 1,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              // Add button
              if (index == selectedImages.length) {
                return GestureDetector(
                  onTap: showImageSourcePicker,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .primaryColor
                          .withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context)
                            .primaryColor
                            .withValues(alpha: 0.2),
                      ),
                    ),
                    child: Icon(Icons.add,
                        color: Theme.of(context).primaryColor),
                  ),
                );
              }

              // Image preview
              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildPreviewImage(selectedImages[index]),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => selectedImages.removeAt(index)),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            '${selectedImages.length} photo${selectedImages.length == 1 ? '' : 's'} added',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.color
                  ?.withValues(alpha: 0.45),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────────

  Widget _sectionLabel(
      BuildContext context, String label, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon,
            size: 16,
            color: theme.textTheme.bodySmall?.color
                ?.withValues(alpha: 0.5)),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            letterSpacing: 0.5,
            color: theme.textTheme.bodySmall?.color
                ?.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }

  Widget _card({required Widget child}) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
}