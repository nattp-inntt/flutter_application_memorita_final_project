import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../data/models/memory_model.dart';
//import '../../../data/repositories/memory_repository.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Map<String, int> getMoodCount(List<Memory> memories) {
    final Map<String, int> data = {};

    for (var m in memories) {
      data[m.mood] = (data[m.mood] ?? 0) + 1;
    }

    return data;
  }

  Map<String, int> getDailyCount(List<Memory> memories) {
    final Map<String, int> data = {};

    for (var m in memories) {
      final key = "${m.date.day}/${m.date.month}";
      data[key] = (data[key] ?? 0) + 1;
    }

    return data;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Statistics")),

      body: ValueListenableBuilder(
        valueListenable: Hive.box<Memory>('memories').listenable(),
        builder: (context, Box<Memory> box, _) {
          final memories = box.values.toList();

          final moodData = getMoodCount(memories);
          final dailyData = getDailyCount(memories);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _section("Mood Distribution"),
              buildPieChart(context, moodData),

              const SizedBox(height: 20),

              _section("Activity Timeline"),
              buildBarChart(context, dailyData),

              const SizedBox(height: 20),

              _section("Insights"),
              buildInsights(context, memories),

              const SizedBox(height: 10),

            ],
          );
        },
      ),
    );
  }

  Widget buildPieChart(BuildContext context, Map<String, int> data) {
    final theme = Theme.of(context);
    if (data.isEmpty) return _emptyChartBox(context);

    final total = data.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return _emptyChartBox(context);

    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: data.entries.map((e) {
            final percent = (e.value / total) * 100;

            return PieChartSectionData(
              value: e.value.toDouble(),
              title: "${e.key}\n${percent.toStringAsFixed(1)}%",
              radius: 60,
              color: getColor(e.key),
              titleStyle: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodyMedium?.color) ?? const TextStyle(color: Colors.black),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget buildBarChart(BuildContext context, Map<String, int> data) {
    final theme = Theme.of(context);
    final entries = data.entries.toList();
    entries.sort((a, b) => a.key.compareTo(b.key));
    if (entries.isEmpty) {
      return _emptyChartBox(context, text: "No activity yet");
    }

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          barGroups: List.generate(entries.length, (i) {
            final e = entries[i];

            return BarChartGroupData(
              x: i,
              barRods: [BarChartRodData(toY: e.value.toDouble(), width: 14)],
            );
          }),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= entries.length) return const SizedBox();
                  return Text(
                    entries[value.toInt()].key,
                    style: theme.textTheme.bodyMedium,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildInsights(BuildContext context, List<Memory> memories) {
  if (memories.isEmpty) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: [
        _emptyInsightCard(
          context,
          title: "Top Mood",
          icon: Icons.emoji_emotions,
        ),
        _emptyInsightCard(
          context,
          title: "Total",
          icon: Icons.book,
        ),
        _emptyInsightCard(
          context,
          title: "Latest",
          icon: Icons.access_time,
        ),
        _emptyInsightCard(
          context,
          title: "Types",
          icon: Icons.category,
        ),
      ],
    );
  }
    final moodCount = getMoodCount(memories);

    final mostMood = moodCount.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );

    final total = memories.length;

    final latest = memories.first.date;

    final percent = (mostMood.value / total * 100).toStringAsFixed(0);


    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: [
        _insightCard(
          title: "Top Mood",
          value: "😶 ${mostMood.key} ($percent%)",
          color: Colors.orange,
          icon: Icons.emoji_emotions,
        ),
        _insightCard(
          title: "Total Memories",
          value: "🗃 $total",
          color: Colors.blue,
          icon: Icons.book,
        ),
        _insightCard(
          title: "Latest Entry",
          value: "🕒 ${latest.day}/${latest.month}",
          color: Colors.green,
          icon: Icons.access_time,
        ),
        _insightCard(
          title: "Mood Types",
          value: "🎨 ${moodCount.length}",
          color: Colors.purple,
          icon: Icons.category,
        ),
      ],
    );
  }

  Widget _insightCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _emptyChartBox(BuildContext context, {String text = "No data yet"}) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return SizedBox(
      height: 200,
      child: Container(
        decoration: BoxDecoration(
          color: onSurface.withOpacity(0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: onSurface.withOpacity(0.12),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.pie_chart_outline,
                size: 40,
                color: onSurface.withOpacity(0.4),
              ),
              const SizedBox(height: 8),
              Text(
                text,
                style: TextStyle(
                  color: onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyInsightCard(BuildContext context, {
    required String title,
    required IconData icon,
  }) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: onSurface.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: onSurface.withOpacity(0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(
            icon,
            color: Colors.white.withOpacity(0.4),
            size: 22,
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "--",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}
