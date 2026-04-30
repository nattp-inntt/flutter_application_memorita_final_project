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

  Future<void> pickFromCamera() async {
    final picked = await picker.pickImage(source: ImageSource.camera);

    if (picked != null) {
      setState(() {
        selectedImages.add(picked);
      });
    }
  }

  Future<void> pickImagesFromGallery() async {
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles.isNotEmpty) {
      setState(() {
        selectedImages.addAll(pickedFiles);
      });
    }
  }

  void pickImage() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Select Image",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 16),

                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text("Take Photo"),
                  onTap: () {
                    Navigator.pop(context);
                    pickFromCamera();
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.photo),
                  title: const Text("Choose multiple from Gallery"),
                  onTap: () {
                    Navigator.pop(context);
                    pickImagesFromGallery();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String selectedMood = 'Happy';
  String customMoodName = 'Custom';
  String customMoodEmoji = '✨';
  DateTime selectedDate = DateTime.now();

  final repo = MemoryRepository();

  final List<String> moods = ['Happy', 'Sad', 'Excited', 'Tired', 'custom'];

  String getMoodEmoji(String mood) {
    switch (mood) {
      case 'Happy':
        return '😊';
      case 'Sad':
        return '😢';
      case 'Excited':
        return '🤩';
      case 'Tired':
        return '😴';
      case 'custom':
        return customMoodEmoji;
      default:
        final trimmed = mood.trim();
        if (trimmed.isEmpty) return '✨';
        return String.fromCharCodes(trimmed.runes.take(1));
    }
  }

  String getMoodLabel(String mood) {
    switch (mood) {
      case 'Happy':
        return 'Happy';
      case 'Sad':
        return 'Sad';
      case 'Excited':
        return 'Excited';
      case 'Tired':
        return 'Tired';
      case 'custom':
        return customMoodName;
      default:
        final parts = mood.split(' ');
        return parts.length > 1 ? parts.sublist(1).join(' ') : mood;
    }
  }

  String getStoredMood() {
    return selectedMood == 'custom'
        ? '$customMoodEmoji $customMoodName'
        : selectedMood;
  }

  Future<void> showCustomMoodDialog() async {
    final controller = TextEditingController(text: customMoodName);
    String tempEmoji = customMoodEmoji;
    const emojiOptions = ['😊', '😢', '🤩', '😴', '😎', '✨', '😍', '😌', '🥰'];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              title: const Text('Custom Mood'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: 'Mood name',
                      hintText: 'Enter a name for your mood',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Choose an emoji'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: emojiOptions.map((emoji) {
                      final isSelected = emoji == tempEmoji;
                      return ChoiceChip(
                        label: Text(emoji, style: const TextStyle(fontSize: 20)),
                        selected: isSelected,
                        onSelected: (_) {
                          dialogSetState(() {
                            tempEmoji = emoji;
                          });
                        },
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
            );
          },
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      customMoodName = controller.text.trim().isEmpty ? customMoodName : controller.text.trim();
      customMoodEmoji = tempEmoji;
      selectedMood = 'custom';
    });
  }

  // 📅 Pick Date
  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  // 💾 Save Memory
  Future<void> saveMemory() async {
    if (!_formKey.currentState!.validate()) return;

    final mediaPaths = <String>[];
    for (final image in selectedImages) {
      mediaPaths.add(await _resolveImagePath(image));
    }

    final memory = Memory(
      id: DateTime.now().toString(),
      title: titleController.text,
      description: descriptionController.text,
      date: selectedDate,
      mood: selectedMood,
      mediaPaths: mediaPaths,
      tags: [],
    );

    await repo.addMemory(memory);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Memory saved!')),
    );

    // 🔙 Go back
    Navigator.pop(context);
  }

  Widget _buildPreviewImage(XFile image) {
    return FutureBuilder<Uint8List>(
      future: image.readAsBytes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        final bytes = snapshot.data;
        if (bytes == null || bytes.isEmpty) {
          return const SizedBox();
        }

        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      },
    );
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

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void showImageSourcePicker() {
  showModalBottomSheet(
    context: context,
    builder: (_) {
      return SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                pickImagesFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                pickFromCamera();
              },
            ),
          ],
        ),
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Memory"),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: saveMemory,
        icon: const Icon(Icons.save),
        label: const Text("Save"),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 📸 Image Picker
              GestureDetector(
                onTap: pickImage, // bottom sheet
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Photos",
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
                          // ➕ Add button
                          if (index == selectedImages.length) {
                            return GestureDetector(
                              onTap: pickImage,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.add),
                              ),
                            );
                          }

                          // 🖼️ Image preview
                          final image = selectedImages[index];

                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _buildPreviewImage(image),
                              ),

                              // ❌ Remove button
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedImages.removeAt(index);
                                    });
                                  },
                                  child: const CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.black54,
                                    child: Icon(Icons.close, size: 14),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 🧾 Title + Description Card
              _card(
                child: Column(
                  children: [
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: "Title",
                        border: InputBorder.none,
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Enter title' : null,
                    ),

                    const Divider(),

                    TextFormField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: "Description",
                        border: InputBorder.none,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 😊 Mood Selector (Chips)
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Mood",
                        style:
                            TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 8,
                      children: moods.map((mood) {
                        final isSelected = selectedMood == mood;

                        return ChoiceChip(
                          label: Text("${getMoodEmoji(mood)} ${getMoodLabel(mood)}"),
                          selected: isSelected,
                          onSelected: (_) {
                            if (mood == 'custom') {
                              showCustomMoodDialog();
                            } else {
                              setState(() {
                                selectedMood = mood;
                              });
                            }
                          },
                          selectedColor: theme.primaryColor,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 📅 Date Picker
              _card(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Date"),
                  subtitle: Text(
                    DateFormat('yyyy-MM-dd').format(selectedDate),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: pickDate,
                ),
              ),

              const SizedBox(height: 80), // space for FAB
            ],
          ),
        ),
      ),
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
      ),
      child: child,
    );
  }
}