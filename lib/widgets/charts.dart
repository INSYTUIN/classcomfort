import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../utils/score_utils.dart';

/// Line chart of the average score per day over the last [days] days.
class TrendChart extends StatelessWidget {
  final List<TrendPoint> points;
  final int days;

  const TrendChart({super.key, required this.points, this.days = trendDays});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return SizedBox(
        height: 120,
        child: Center(child: Text('No ratings in the last $days days.')),
      );
    }

    final today = DateTime.now();
    final color = Theme.of(context).colorScheme.primary;

    return SizedBox(
      height: 220,
      child: Padding(
        padding: const EdgeInsets.only(right: 16, top: 8),
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: (days - 1).toDouble(),
            minY: 1,
            maxY: 5,
            gridData: FlGridData(show: true, drawVerticalLine: false),
            borderData: FlBorderData(show: false),
            // Dashed red line at the "needs attention" level
            extraLinesData: ExtraLinesData(
              horizontalLines: [
                HorizontalLine(
                  y: problemThreshold,
                  color: Colors.red.shade300,
                  strokeWidth: 1,
                  dashArray: [6, 4],
                ),
              ],
            ),
            titlesData: FlTitlesData(
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) => Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: (days - 1) / 4,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) {
                    // x = 0 is the oldest day, x = days - 1 is today
                    final date = DateTime(
                      today.year,
                      today.month,
                      today.day - (days - 1) + value.round(),
                    );
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${date.day}/${date.month}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    );
                  },
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: [for (final p in points) FlSpot(p.x.toDouble(), p.value)],
                isCurved: false,
                color: color,
                barWidth: 3,
                dotData: FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: color.withValues(alpha: 0.15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A trend chart with chips to switch between the overall score and each factor.
/// [pointsFor] returns the points for a factor (null = overall score).
class TrendSection extends StatefulWidget {
  final List<TrendPoint> Function(String? factor) pointsFor;

  const TrendSection({super.key, required this.pointsFor});

  @override
  State<TrendSection> createState() => _TrendSectionState();
}

class _TrendSectionState extends State<TrendSection> {
  String? _factor; // null = overall score

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final option in <String?>[null, ...factors])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(option ?? 'Overall'),
                    selected: _factor == option,
                    onSelected: (_) => setState(() => _factor = option),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TrendChart(points: widget.pointsFor(_factor)),
        const Text(
          'Dashed red line = 3.0. Scores below it need attention.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}

/// Bar chart comparing the average score of each classroom.
/// Each entry is (room label, score).
class ClassroomBarChart extends StatelessWidget {
  final List<MapEntry<String, double>> entries;

  const ClassroomBarChart({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const Text('No ratings yet.');

    return LayoutBuilder(
      builder: (context, constraints) {
        // Give every bar enough room; scroll sideways if there are many rooms.
        final neededWidth = entries.length * 56.0;
        final width =
            neededWidth > constraints.maxWidth ? neededWidth : constraints.maxWidth;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            height: 220,
            child: Padding(
              padding: const EdgeInsets.only(right: 16, top: 8),
              child: BarChart(
                BarChartData(
                  minY: 0,
                  maxY: 5,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= entries.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              entries[i].key,
                              style: const TextStyle(fontSize: 11),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < entries.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: entries[i].value,
                            color: scoreColor(entries[i].value),
                            width: 22,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
