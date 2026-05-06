import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/themes.dart';
import '../../../data/models/memory_model.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int _touchedPieIndex = -1;

  // ── Data helpers ────────────────────────────────────────────────────────────

  Map<String, int> getMoodCount(List<Memory> memories) {
    final Map<String, int> data = {};
    for (var m in memories) {
      data[m.mood] = (data[m.mood] ?? 0) + 1;
    }
    return data;
  }

  // Returns last 7 days of activity (fills 0 for missing days)
  List<MapEntry<String, int>> getLast7Days(List<Memory> memories) {
    final now = DateTime.now();
    final result = <MapEntry<String, int>>[];

    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final key = DateTime(day.year, day.month, day.day);
      final count = memories.where((m) {
        final d = DateTime(m.date.year, m.date.month, m.date.day);
        return d == key;
      }).length;

      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final label = i == 0 ? 'Today' : weekdays[day.weekday - 1];
      result.add(MapEntry(label, count));
    }

    return result;
  }

  int getCurrentStreak(List<Memory> memories) {
    if (memories.isEmpty) return 0;
    final now = DateTime.now();
    int streak = 0;

    for (int i = 0; i < 365; i++) {
      final day = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: i));
      final hasEntry = memories.any((m) {
        final d = DateTime(m.date.year, m.date.month, m.date.day);
        return d == day;
      });
      if (hasEntry) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  Color getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':   return const Color(0xFFFBBF24);
      case 'sad':     return const Color(0xFF60A5FA);
      case 'excited': return const Color(0xFFF97316);
      case 'tired':   return const Color(0xFFA78BFA);
      default:        return Colors.grey;
    }
  }

  String getMoodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':   return '😊';
      case 'sad':     return '😢';
      case 'excited': return '🤩';
      case 'tired':   return '😴';
      default:        return '🙂';
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkTimeline
          : AppColors.lightTimeline,
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkTimeline
          : AppColors.lightTimeline,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Statistics',
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

          final moodData = getMoodCount(memories);
          final weekData = getLast7Days(memories);
          final streak = getCurrentStreak(memories);
          final withPhotos = memories.where((m) => m.mediaPaths.isNotEmpty).length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
            children: [
              // ── Summary cards row ─────────────────────────────────
              _buildSummaryRow(context, memories, moodData, streak, withPhotos),

              const SizedBox(height: 20),

              // ── Mood distribution ─────────────────────────────────
              _sectionTitle(context, 'Mood Distribution'),
              const SizedBox(height: 12),
              _buildMoodSection(context, moodData, memories.length),

              const SizedBox(height: 24),

              // ── Weekly activity bar chart ─────────────────────────
              _sectionTitle(context, 'Last 7 Days'),
              const SizedBox(height: 12),
              _buildWeeklyChart(context, weekData),

              const SizedBox(height: 24),

              // ── Mood breakdown list ───────────────────────────────
              if (moodData.isNotEmpty) ...[
                _sectionTitle(context, 'Mood Breakdown'),
                const SizedBox(height: 12),
                _buildMoodBreakdown(context, moodData, memories.length),
                const SizedBox(height: 24),
              ],
            ],
          );
        },
      ),
    );
  }

  // ── Summary row ─────────────────────────────────────────────────────────────

  Widget _buildSummaryRow(
    BuildContext context,
    List<Memory> memories,
    Map<String, int> moodData,
    int streak,
    int withPhotos,
  ) {
    final total = memories.length;

    String topMood = '-';
    String topMoodEmoji = '🙂';
    if (moodData.isNotEmpty) {
      final top =
          moodData.entries.reduce((a, b) => a.value > b.value ? a : b);
      topMood = top.key;
      topMoodEmoji = getMoodEmoji(top.key);
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _summaryCard(
                context,
                label: 'Total',
                value: '$total',
                icon: Icons.auto_stories_outlined,
                iconColor: const Color(0xFF60A5FA),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _summaryCard(
                context,
                label: 'Streak',
                value: '$streak ${streak == 1 ? 'day' : 'days'}',
                icon: Icons.local_fire_department_outlined,
                iconColor: const Color(0xFFF97316),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _summaryCard(
                context,
                label: 'Top Mood',
                value: '$topMoodEmoji $topMood',
                icon: Icons.emoji_emotions_outlined,
                iconColor: const Color(0xFFFBBF24),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _summaryCard(
                context,
                label: 'With Photos',
                value: '$withPhotos',
                icon: Icons.photo,
                iconColor: const Color(0xFF10B981),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
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
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color
                  ?.withValues(alpha: 0.5),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ── Mood pie chart + legend ──────────────────────────────────────────────────

  Widget _buildMoodSection(
      BuildContext context, Map<String, int> data, int total) {
    final theme = Theme.of(context);

    if (data.isEmpty) return _emptyBox(context);

    final entries = data.entries.toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          // Pie chart
          SizedBox(
            width: 140,
            height: 140,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          response == null ||
                          response.touchedSection == null) {
                        _touchedPieIndex = -1;
                        return;
                      }
                      _touchedPieIndex =
                          response.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sectionsSpace: 3,
                centerSpaceRadius: 30,
                sections: List.generate(entries.length, (i) {
                  final e = entries[i];
                  final isTouched = i == _touchedPieIndex;
                  final radius = isTouched ? 52.0 : 44.0;

                  return PieChartSectionData(
                    value: e.value.toDouble(),
                    color: getMoodColor(e.key),
                    radius: radius,
                    title: '',
                    badgeWidget: isTouched
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${(e.value / total * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 11),
                            ),
                          )
                        : null,
                    badgePositionPercentageOffset: 1.3,
                  );
                }),
              ),
            ),
          ),

          const SizedBox(width: 20),

          // Legend
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: entries.map((e) {
                final pct =
                    (e.value / total * 100).toStringAsFixed(1);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: getMoodColor(e.key),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${getMoodEmoji(e.key)} ${e.key}',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontSize: 13),
                        ),
                      ),
                      Text(
                        '$pct%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: getMoodColor(e.key),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Weekly bar chart ─────────────────────────────────────────────────────────

  Widget _buildWeeklyChart(
      BuildContext context, List<MapEntry<String, int>> data) {
    final theme = Theme.of(context);
    final maxY =
        data.map((e) => e.value).fold<int>(1, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.12)),
      ),
      child: SizedBox(
        height: 180,
        child: BarChart(
          BarChartData(
            maxY: (maxY + 1).toDouble(),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 1,
              getDrawingHorizontalLine: (value) => FlLine(
                color: theme.dividerColor.withValues(alpha: 0.15),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i < 0 || i >= data.length) {
                      return const SizedBox();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        data[i].key,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: theme.textTheme.bodySmall?.color
                              ?.withValues(alpha: 0.6),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            barGroups: List.generate(data.length, (i) {
              final isToday = i == data.length - 1;
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: data[i].value.toDouble(),
                    width: 22,
                    borderRadius: BorderRadius.circular(6),
                    color: isToday
                        ? theme.primaryColor
                        : theme.primaryColor.withValues(alpha: 0.35),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: (maxY + 1).toDouble(),
                      color: theme.primaryColor.withValues(alpha: 0.05),
                    ),
                  ),
                ],
              );
            }),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => Colors.black87,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final count = rod.toY.toInt();
                  return BarTooltipItem(
                    '$count ${count == 1 ? 'memory' : 'memories'}',
                    const TextStyle(
                        color: Colors.white, fontSize: 12),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Mood breakdown rows ──────────────────────────────────────────────────────

  Widget _buildMoodBreakdown(
      BuildContext context, Map<String, int> data, int total) {
    final theme = Theme.of(context);
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: entries.map((e) {
          final pct = e.value / total;
          final color = getMoodColor(e.key);

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${getMoodEmoji(e.key)}  ${e.key}',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '${e.value} ${e.value == 1 ? 'time' : 'times'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color
                            ?.withValues(alpha: 0.55),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 7,
                    backgroundColor:
                        color.withValues(alpha: 0.12),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Shared widgets ───────────────────────────────────────────────────────────

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Widget _emptyBox(BuildContext context,
      {String text = 'No data yet'}) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: onSurface.withValues(alpha: 0.1)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_outlined,
                size: 36,
                color: onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: 8),
            Text(
              text,
              style: TextStyle(
                  color: onSurface.withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }
}