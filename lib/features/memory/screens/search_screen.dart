import 'package:flutter/material.dart';
import '../../../data/models/memory_model.dart';
import '../../../data/repositories/memory_repository.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/universal_image_provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final repo = MemoryRepository();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<Memory> allMemories = [];
  List<Memory> filteredMemories = [];

  // Filters
  String _selectedMood = 'All';
  DateTimeRange? _selectedDateRange;
  bool _hasSearched = false;

  static const List<String> _moods = [
    'All', 'Happy', 'Sad', 'Excited', 'Tired'
  ];

  @override
  void initState() {
    super.initState();
    allMemories = repo.getAllMemories()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Filter logic ────────────────────────────────────────────────────────────

  void _applyFilters() {
    final query = _searchController.text.toLowerCase().trim();

    List<Memory> results = allMemories.where((m) {
      // Mood filter
      if (_selectedMood != 'All' &&
          m.mood.toLowerCase() != _selectedMood.toLowerCase()) {
        return false;
      }

      // Date range filter
      if (_selectedDateRange != null) {
        final d = DateTime(m.date.year, m.date.month, m.date.day);
        final start = DateTime(
          _selectedDateRange!.start.year,
          _selectedDateRange!.start.month,
          _selectedDateRange!.start.day,
        );
        final end = DateTime(
          _selectedDateRange!.end.year,
          _selectedDateRange!.end.month,
          _selectedDateRange!.end.day,
        );
        if (d.isBefore(start) || d.isAfter(end)) return false;
      }

      // Text search
      if (query.isNotEmpty) {
        final title = m.title.toLowerCase();
        final desc = m.description.toLowerCase();
        final tags = m.tags.join(' ').toLowerCase();
        if (!title.contains(query) &&
            !desc.contains(query) &&
            !tags.contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();

    setState(() {
      filteredMemories = results;
      _hasSearched = query.isNotEmpty ||
          _selectedMood != 'All' ||
          _selectedDateRange != null;
    });
  }

  void _clearAll() {
    _searchController.clear();
    setState(() {
      _selectedMood = 'All';
      _selectedDateRange = null;
      _hasSearched = false;
      filteredMemories = [];
    });
  }

  bool get _hasActiveFilters =>
      _selectedMood != 'All' || _selectedDateRange != null;

  // ── Date range picker ────────────────────────────────────────────────────────

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: _selectedDateRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme,
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() => _selectedDateRange = picked);
      _applyFilters();
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _getMoodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':   return '😊';
      case 'sad':     return '😢';
      case 'excited': return '🤩';
      case 'tired':   return '😴';
      default:        return '🙂';
    }
  }

  Color _getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':   return const Color(0xFFFBBF24);
      case 'sad':     return const Color(0xFF60A5FA);
      case 'excited': return const Color(0xFFF97316);
      case 'tired':   return const Color(0xFFA78BFA);
      default:        return Colors.grey;
    }
  }

  // Highlight matched text in search results
  List<TextSpan> _highlightText(String text, String query) {
    if (query.isEmpty) {
      return [TextSpan(text: text)];
    }

    final spans = <TextSpan>[];
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    int start = 0;

    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: TextStyle(
          backgroundColor:
              Theme.of(context).primaryColor.withValues(alpha: 0.3),
          fontWeight: FontWeight.w600,
        ),
      ));
      start = index + query.length;
    }

    return spans;
  }

  // ── Build ────────────────────────────────────────────────────────────────────

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
          'Search',
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_hasSearched || _hasActiveFilters)
            TextButton(
              onPressed: _clearAll,
              child: Text(
                'Clear',
                style: TextStyle(color: theme.primaryColor),
              ),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Search bar ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              onChanged: (_) => _applyFilters(),
              decoration: InputDecoration(
                hintText: 'Search by title, description, tags...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilters();
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.15),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: theme.primaryColor.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Mood filter chips ──────────────────────────────────────
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _moods.length + 1, // +1 for date range chip
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                // Date range chip at the end
                if (index == _moods.length) {
                  final isActive = _selectedDateRange != null;
                  return FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.date_range,
                          size: 14,
                          color: isActive
                              ? theme.primaryColor
                              : theme.textTheme.bodySmall?.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isActive
                              ? '${_formatDate(_selectedDateRange!.start)} – ${_formatDate(_selectedDateRange!.end)}'
                              : 'Date range',
                          style: TextStyle(
                            fontSize: 12,
                            color: isActive
                                ? theme.primaryColor
                                : null,
                          ),
                        ),
                        if (isActive) ...[
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              setState(
                                  () => _selectedDateRange = null);
                              _applyFilters();
                            },
                            child: Icon(Icons.close,
                                size: 14,
                                color: theme.primaryColor),
                          ),
                        ],
                      ],
                    ),
                    selected: isActive,
                    onSelected: (_) => _pickDateRange(),
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 0),
                    visualDensity: VisualDensity.compact,
                  );
                }

                // Mood chips
                final mood = _moods[index];
                final isSelected = _selectedMood == mood;
                return FilterChip(
                  label: Text(
                    mood == 'All'
                        ? 'All moods'
                        : '${_getMoodEmoji(mood)} $mood',
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? theme.primaryColor : null,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() => _selectedMood = mood);
                    _applyFilters();
                  },
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 0),
                  visualDensity: VisualDensity.compact,
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // ── Result count / state label ────────────────────────────
          if (_hasSearched)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                filteredMemories.isEmpty
                    ? 'No results found'
                    : '${filteredMemories.length} result${filteredMemories.length == 1 ? '' : 's'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color
                      ?.withValues(alpha: 0.55),
                  fontSize: 13,
                ),
              ),
            ),

          if (_hasSearched) const SizedBox(height: 8),

          // ── Results list ───────────────────────────────────────────
          Expanded(
            child: !_hasSearched
                ? _buildIdleState(context)
                : filteredMemories.isEmpty
                    ? _buildEmptyState(context)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                            16, 0, 16, 40),
                        itemCount: filteredMemories.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          return _buildResultCard(
                            context,
                            filteredMemories[index],
                            _searchController.text.trim(),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // ── Result card ──────────────────────────────────────────────────────────────

  Widget _buildResultCard(
      BuildContext context, Memory memory, String query) {
    final theme = Theme.of(context);
    final hasImage = memory.mediaPaths.isNotEmpty;
    final moodColor = _getMoodColor(memory.mood);

    return GestureDetector(
      onTap: () async {
        await Navigator.pushNamed(
          context,
          AppRoutes.memoryDetail,
          arguments: memory,
        );
        setState(() {
          allMemories = repo.getAllMemories()
            ..sort((a, b) => b.date.compareTo(a.date));
        });
        _applyFilters();
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.12),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            if (hasImage)
              Image(
                image:
                    universalImageProvider(memory.mediaPaths.first),
                width: 90,
                height: 90,
                fit: BoxFit.cover,
              )
            else
              Container(
                width: 90,
                height: 90,
                color: moodColor.withValues(alpha: 0.12),
                child: Center(
                  child: Text(
                    _getMoodEmoji(memory.mood),
                    style: const TextStyle(fontSize: 30),
                  ),
                ),
              ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title with highlight
                    RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        children:
                            _highlightText(memory.title, query),
                      ),
                    ),

                    // Description with highlight
                    if (memory.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      RichText(
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color
                                ?.withValues(alpha: 0.6),
                            fontSize: 12,
                            height: 1.4,
                          ),
                          children: _highlightText(
                              memory.description, query),
                        ),
                      ),
                    ],

                    const SizedBox(height: 8),

                    // Mood + date row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color:
                                moodColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_getMoodEmoji(memory.mood)} ${memory.mood}',
                            style: TextStyle(
                              fontSize: 11,
                              color: moodColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(memory.date),
                          style:
                              theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: theme.textTheme.bodySmall?.color
                                ?.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Idle state (nothing searched yet) ───────────────────────────────────────

  Widget _buildIdleState(BuildContext context) {
    final theme = Theme.of(context);

    // Recent memories as quick suggestions
    final recent = allMemories.take(5).toList();

    if (recent.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search,
                size: 56,
                color: theme.textTheme.bodySmall?.color
                    ?.withValues(alpha: 0.25)),
            const SizedBox(height: 12),
            Text(
              'Search your memories',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color
                    ?.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
      children: [
        Text(
          'Recent memories',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodySmall?.color
                ?.withValues(alpha: 0.5),
            fontSize: 12,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 10),
        ...recent.map(
          (m) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildResultCard(context, m, ''),
          ),
        ),
      ],
    );
  }

  // ── Empty state ──────────────────────────────────────────────────────────────

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off,
              size: 52,
              color: theme.textTheme.bodySmall?.color
                  ?.withValues(alpha: 0.25)),
          const SizedBox(height: 12),
          Text(
            'No memories found',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color
                  ?.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try different keywords or filters',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color
                  ?.withValues(alpha: 0.35),
            ),
          ),
        ],
      ),
    );
  }
}