import 'package:flutter/material.dart';
import '../../../data/models/memory_model.dart';
import '../../../shared/widgets/universal_image_provider.dart';

class MemoryCard extends StatefulWidget {
  final Memory memory;
  final VoidCallback? onTap;

  const MemoryCard({super.key, required this.memory, this.onTap});

  @override
  State<MemoryCard> createState() => _MemoryCardState();
}

class _MemoryCardState extends State<MemoryCard> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  String formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

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
      default:
        final trimmed = mood.trim();
        if (trimmed.isEmpty) return '🙂';
        return String.fromCharCodes(trimmed.runes.take(1));
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final memory = widget.memory;
    final hasImage = memory.mediaPaths.isNotEmpty;
    final hasMultipleImages = memory.mediaPaths.length > 1;

    return Card(
      color: Theme.of(context).cardColor,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImage)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Stack(
                  children: [
                    SizedBox(
                      height: 200,
                      width: double.infinity,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: memory.mediaPaths.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentPage = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          return Image(
                            image: universalImageProvider(memory.mediaPaths[index]),
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    ),
                    if (hasMultipleImages)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_currentPage + 1}/${memory.mediaPaths.length}',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                    if (hasMultipleImages)
                      Positioned(
                        left: 8,
                        top: 0,
                        bottom: 0,
                        child: Visibility(
                          visible: _currentPage > 0,
                          child: GestureDetector(
                            onTap: () {
                              if (_currentPage > 0) {
                                _pageController.previousPage(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeInOut,
                                );
                              }
                            },
                            child: Container(
                              width: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.chevron_left,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (hasMultipleImages)
                      Positioned(
                        right: 8,
                        top: 0,
                        bottom: 0,
                        child: Visibility(
                          visible: _currentPage < memory.mediaPaths.length - 1,
                          child: GestureDetector(
                            onTap: () {
                              if (_currentPage < memory.mediaPaths.length - 1) {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeInOut,
                                );
                              }
                            },
                            child: Container(
                              width: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.chevron_right,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          memory.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        getMoodEmoji(memory.mood),
                        style: const TextStyle(fontSize: 20),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  if (memory.description.isNotEmpty)
                    Text(
                      memory.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                  const SizedBox(height: 6),

                  Text(
                    formatDate(memory.date),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
