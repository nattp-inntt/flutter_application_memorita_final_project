import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../data/models/memory_model.dart';
import '../../../data/repositories/memory_repository.dart';
import '../../../routes/app_routes.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int)? onTabChange;

  const DashboardScreen({super.key, this.onTabChange});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final repo = MemoryRepository();

  int totalMemories = 0;
  String mostMood = '-';
  int streak = 0;

  @override
  void initState() {
    super.initState();
    loadStats();
  }

  void loadStats() {
    final memories = repo.getAllMemories();
    totalMemories = memories.length;

    if (memories.isNotEmpty) {
      // Top mood
      final moodCount = <String, int>{};
      for (var m in memories) {
        moodCount[m.mood] = (moodCount[m.mood] ?? 0) + 1;
      }
      mostMood =
          moodCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;

      // Writing streak
      final now = DateTime.now();
      int s = 0;
      for (int i = 0; i < 365; i++) {
        final day = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: i));
        final hasEntry = memories.any((m) {
          final d = DateTime(m.date.year, m.date.month, m.date.day);
          return d == day;
        });
        if (hasEntry) {
          s++;
        } else {
          break;
        }
      }
      streak = s;
    }

    setState(() {});
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good Morning 🌅';
    if (hour >= 12 && hour < 17) return 'Good Afternoon ☀️';
    if (hour >= 17 && hour < 21) return 'Good Evening 🌆';
    return 'Good Night 🌙';
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

  Map<DateTime, List<Memory>> groupByDay(List<Memory> memories) {
    final Map<DateTime, List<Memory>> map = {};
    for (var m in memories) {
      final date = DateTime(m.date.year, m.date.month, m.date.day);
      map.putIfAbsent(date, () => []).add(m);
    }
    return map;
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero header ──────────────────────────────────────────
            _buildHeader(context, isDark),

            // ── Stats row ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _statCard(
                      context,
                      label: 'Memories',
                      value: '$totalMemories',
                      icon: Icons.auto_stories_outlined,
                      color: const Color(0xFF60A5FA),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _statCard(
                      context,
                      label: 'Day Streak',
                      value: '$streak 🔥',
                      icon: Icons.local_fire_department_outlined,
                      color: const Color(0xFFF97316),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _statCard(
                      context,
                      label: 'Top Mood',
                      value: mostMood == '-'
                          ? '-'
                          : _getMoodEmoji(mostMood),
                      icon: Icons.emoji_emotions_outlined,
                      color: mostMood == '-'
                          ? Colors.grey
                          : _getMoodColor(mostMood),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Quick actions ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _sectionTitle(context, 'Quick Actions'),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _quickActionCard(
                      context,
                      label: 'New Memory',
                      subtitle: 'Write something',
                      icon: Icons.edit_outlined,
                      color: const Color(0xFF6C63FF),
                      onTap: () async {
                        await Navigator.pushNamed(
                            context, AppRoutes.addMemory);
                        loadStats();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _quickActionCard(
                      context,
                      label: 'Search',
                      subtitle: 'Find a memory',
                      icon: Icons.search_outlined,
                      color: const Color(0xFF10B981),
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.search),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _quickActionCard(
                      context,
                      label: 'Timeline',
                      subtitle: 'View all entries',
                      icon: Icons.timeline_outlined,
                      color: const Color(0xFFF59E0B),
                      onTap: () => widget.onTabChange?.call(1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _quickActionCard(
                      context,
                      label: 'Stats',
                      subtitle: 'Mood insights',
                      icon: Icons.bar_chart_outlined,
                      color: const Color(0xFFF97316),
                      onTap: () => widget.onTabChange?.call(4),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Activity calendar ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _sectionTitle(context, 'Your Activity'),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
              child: _buildCalendar(isDark),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hero header with app name + greeting ─────────────────────────────────────

  Widget _buildHeader(BuildContext context, bool isDark) {
    // ignore: unused_local_variable
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 16,
        20,
        24,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? const Color.fromARGB(255, 78, 69, 255)
            : const Color(0xFF6C63FF),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App name row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.book_outlined,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Memorita',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              // Settings shortcut
              GestureDetector(
                onTap: () => widget.onTabChange?.call(3),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.settings_outlined,
                      color: Colors.white, size: 18),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Greeting
          Text(
            _getGreeting(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'What is your story today?',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ── Stat card ──────────────────────────────────────────────────────────────

  Widget _statCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: theme.textTheme.bodySmall?.color
                  ?.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  // ── Quick action card ──────────────────────────────────────────────────────

  Widget _quickActionCard(
    BuildContext context, {
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: theme.textTheme.bodySmall?.color
                          ?.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 16,
              color: theme.iconTheme.color?.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section title ──────────────────────────────────────────────────────────

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
    );
  }

  // ── Calendar ───────────────────────────────────────────────────────────────

  Widget _buildCalendar(bool isDark) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Memory>('memories').listenable(),
      builder: (context, Box<Memory> box, _) {
        final theme = Theme.of(context);
        final memories = box.values.toList();
        final grouped = groupByDay(memories);

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF252538)
                : theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: isDark
                ? Border.all(
                    color: Colors.white.withValues(alpha: 0.06))
                : Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.45,
            child: TableCalendar(
              firstDay: DateTime(2020),
              lastDay: DateTime(2100),
              focusedDay: DateTime.now(),
              headerStyle: HeaderStyle(
                titleTextStyle:
                    theme.textTheme.titleMedium ?? const TextStyle(),
                formatButtonVisible: false,
                leftChevronIcon: Icon(Icons.chevron_left,
                    color: theme.iconTheme.color),
                rightChevronIcon: Icon(Icons.chevron_right,
                    color: theme.iconTheme.color),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle:
                    theme.textTheme.bodySmall ?? const TextStyle(),
                weekendStyle:
                    theme.textTheme.bodySmall ?? const TextStyle(),
              ),
              calendarStyle: CalendarStyle(
                defaultTextStyle:
                    theme.textTheme.bodyMedium ?? const TextStyle(),
                weekendTextStyle:
                    theme.textTheme.bodyMedium ?? const TextStyle(),
                outsideDaysVisible: false,
                todayDecoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: theme.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  final key =
                      DateTime(day.year, day.month, day.day);
                  if (grouped.containsKey(key)) {
                    final mood =
                        grouped[key]?.first.mood ?? 'neutral';
                    return Container(
                      margin: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: _getMoodColor(mood)
                            .withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                    );
                  }
                  return null;
                },
              ),
              calendarFormat: CalendarFormat.month,
              rowHeight: 36,
              availableCalendarFormats: const {
                CalendarFormat.month: 'Month',
              },
            ),
          ),
        );
      },
    );
  }
}