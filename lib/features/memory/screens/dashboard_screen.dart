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
  String mostMood = "-";

  @override
  void initState() {
    super.initState();
    loadStats();
  }

  void loadStats() {
    final memories = repo.getAllMemories();

    totalMemories = memories.length;

    if (memories.isNotEmpty) {
      final moodCount = <String, int>{};

      for (var m in memories) {
        moodCount[m.mood] = (moodCount[m.mood] ?? 0) + 1;
      }

      mostMood = moodCount.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }

    setState(() {});
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return "Good Morning 🌅";
    } else if (hour >= 12 && hour < 17) {
      return "Good Afternoon ☀️";
    } else if (hour >= 17 && hour < 21) {
      return "Good Evening 🌆";
    } else {
      return "Good Night 🌙";
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        children: [
          // 🔷 Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor,
                  theme.primaryColor.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 22,
                  ),
                ),

                const SizedBox(height: 16),

                // 🔘 Action Cards
                Row(
                  children: [
                    Expanded(
                      child: _actionCard(
                        context,
                        "Add Memory",
                        Icons.add,
                        () async {
                          await Navigator.pushNamed(
                              context, AppRoutes.addMemory);
                          loadStats(); // refresh
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _actionCard(
                        context,
                        "Search",
                        Icons.search,
                        () {
                          Navigator.pushNamed(context, AppRoutes.search);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 📊 Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _statCard("Total Memories", "$totalMemories"),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard("Top Mood", mostMood),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 📂 Navigation Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Explore",
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                _navCard(
                  "View Timeline",
                  Icons.timeline,
                  () {
                    widget.onTabChange?.call(1); // switch tab
                  },
                ),

                const SizedBox(height: 12),

                _navCard(
                  "Search Memories",
                  Icons.search,
                  () {
                    widget.onTabChange?.call(2);
                  },
                ),           
              ],
            ),
          ),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Your Activity",
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                _buildCalendar(),
                const SizedBox(height: 42), // bottom padding
              ],
            ),
          ),

        ],
      ),
    );
  }

  // 🔘 Action Card
  Widget _actionCard(
      BuildContext context, String title, IconData icon, VoidCallback onTap) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: theme.textTheme.bodyLarge),
            Icon(icon, color: theme.iconTheme.color),
          ],
        ),
      ),
    );
  }

  // 📊 Stat Card
  Widget _statCard(String title, String value) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(value, style: textTheme.titleLarge?.copyWith(fontSize: 20)),
          const SizedBox(height: 4),
          Text(title, style: textTheme.bodyMedium),
        ],
      ),
    );
  }

  // 📂 Navigation Card
  Widget _navCard(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: Theme.of(context).textTheme.bodyLarge),
            Icon(icon, color: Theme.of(context).iconTheme.color),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Memory>('memories').listenable(),
      builder: (context, Box<Memory> box, _) {
        final theme = Theme.of(context);
        final memories = box.values.toList();
        final grouped = groupByDay(memories);

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.cardColor.withValues(alpha: theme.brightness == Brightness.dark ? 0.12 : 0.95),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.12),
                blurRadius: 18,
                spreadRadius: 1,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: TableCalendar(
              firstDay: DateTime(2020),
              lastDay: DateTime(2100),
              focusedDay: DateTime.now(),
              headerStyle: HeaderStyle(
                titleTextStyle: theme.textTheme.titleMedium ?? const TextStyle(),
                formatButtonVisible: false,
                leftChevronIcon: Icon(Icons.chevron_left, color: theme.iconTheme.color),
                rightChevronIcon: Icon(Icons.chevron_right, color: theme.iconTheme.color),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: theme.textTheme.bodyMedium ?? const TextStyle(),
                weekendStyle: theme.textTheme.bodyMedium ?? const TextStyle(),
              ),
              calendarStyle: CalendarStyle(
                defaultTextStyle: theme.textTheme.bodyMedium ?? const TextStyle(),
                weekendTextStyle: theme.textTheme.bodyMedium ?? const TextStyle(),
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
                  final key = DateTime(day.year, day.month, day.day);

                  if (grouped.containsKey(key)) {
                    final mood = grouped[key]?.first.mood;
                    return Container(
                      margin: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: getColor(mood ?? 'neutral').withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            color: theme.brightness == Brightness.dark
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
              rowHeight: 38,
              availableCalendarFormats: const {
                CalendarFormat.month: 'Month',
              },
            ),
          ),
        );
      },
    );
  }

  Color getColor(String mood) {
    switch (mood) {
      case 'Happy':
        return Colors.yellow;
      case 'Sad':
        return Colors.blue;
      case 'Excited':
        return Colors.orange;
      case 'Tired':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
