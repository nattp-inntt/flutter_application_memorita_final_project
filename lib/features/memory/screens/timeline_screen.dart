import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../data/models/memory_model.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/universal_image_provider.dart';

class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key});

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _groupLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = today.difference(d).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return _formatShort(date);
  }

  String _formatShort(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  String _formatFull(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Color _labelColor(String label, BuildContext context) {
    if (label == 'Today') return const Color(0xFFA78BFA);     // purple
    if (label == 'Yesterday') return const Color(0xFF60A5FA); // blue
    return const Color(0xFF6EE7B7);                           // teal
  }

  String _moodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':   return '😊';
      case 'sad':     return '😢';
      case 'excited': return '🤩';
      case 'tired':   return '😴';
      default:        return '🙂';
    }
  }

  // ── Group memories by day ──────────────────────────────────────────────────

  List<MapEntry<DateTime, List<Memory>>> _grouped(List<Memory> memories) {
    final map = <DateTime, List<Memory>>{};
    for (final m in memories) {
      final key = DateTime(m.date.year, m.date.month, m.date.day);
      map.putIfAbsent(key, () => []).add(m);
    }
    final sorted = map.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    return sorted;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Timeline',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Memory>('memories').listenable(),
        builder: (context, Box<Memory> box, _) {
          final memories = box.values.toList()
            ..sort((a, b) => b.date.compareTo(a.date));

          if (memories.isEmpty) {
            return _buildEmpty(context);
          }

          final groups = _grouped(memories);

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final entry = groups[index];
              final label = _groupLabel(entry.key);
              final color = _labelColor(label, context);
              final isLast = index == groups.length - 1;

              return _buildGroup(
                context,
                date: entry.key,
                label: label,
                labelColor: color,
                memories: entry.value,
                isLast: isLast,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.addMemory),
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ── Group row (date label + vertical line + cards) ─────────────────────────

  Widget _buildGroup(
    BuildContext context, {
    required DateTime date,
    required String label,
    required Color labelColor,
    required List<Memory> memories,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left: dot + line
          SizedBox(
            width: 24,
            child: Column(
              children: [
                const SizedBox(height: 3),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: labelColor,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Container(
                      width: 2,
                      color: isLast
                          ? Colors.transparent
                          : labelColor.withValues(alpha: 0.25),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          // Right: label + cards
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date label row
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: labelColor,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatFull(date),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.color
                              ?.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),

                // Memory cards for this day
                ...memories.map(
                  (m) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildMemoryCard(context, m),
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Memory card ────────────────────────────────────────────────────────────

  Widget _buildMemoryCard(BuildContext context, Memory memory) {
    final hasImage = memory.mediaPaths.isNotEmpty;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.memoryDetail,
        arguments: memory,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.15),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: hasImage
            ? _imageCard(context, memory)
            : _textCard(context, memory),
      ),
    );
  }

  // Card with hero image
  Widget _imageCard(BuildContext context, Memory memory) {
    final theme = Theme.of(context);
    final extraCount = memory.mediaPaths.length - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image with overlays
        Stack(
          children: [
            Image(
              image: universalImageProvider(memory.mediaPaths.first),
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
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
                      Colors.black.withValues(alpha: 0.5),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
            ),
            // Mood badge top-right
            Positioned(
              top: 10,
              right: 10,
              child: _moodBadge(memory.mood),
            ),
            // Extra photo count badge bottom-right
            if (extraCount > 0)
              Positioned(
                bottom: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '+$extraCount photo${extraCount > 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
          ],
        ),

        // Title + date
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                memory.title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${_moodEmoji(memory.mood)}  ${memory.mood} · ${_formatShort(memory.date)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color
                      ?.withValues(alpha: 0.55),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Text-only card (no image)
  Widget _textCard(BuildContext context, Memory memory) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  memory.title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (memory.description.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    memory.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color
                          ?.withValues(alpha: 0.55),
                      height: 1.5,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  '${_moodEmoji(memory.mood)}  ${memory.mood} · ${_formatShort(memory.date)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color
                        ?.withValues(alpha: 0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(_moodEmoji(memory.mood), style: const TextStyle(fontSize: 22)),
        ],
      ),
    );
  }

  // Mood emoji badge
  Widget _moodBadge(String mood) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _moodEmoji(mood),
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  // Empty state
  Widget _buildEmpty(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_stories_outlined,
              size: 64,
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            'No memories yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first memory',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.35),
            ),
          ),
        ],
      ),
    );
  }
}