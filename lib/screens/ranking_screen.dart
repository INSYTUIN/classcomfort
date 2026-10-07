import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/data_service.dart';
import '../utils/score_utils.dart';

/// Ranks classrooms by comfort score and compares every factor side by side.
class RankingScreen extends StatelessWidget {
  const RankingScreen({super.key});

  DataCell _factorCell(double? value) {
    if (value == null) return const DataCell(Text('-'));
    final low = value < problemThreshold;
    return DataCell(
      Text(
        value.toStringAsFixed(1),
        style: TextStyle(
          color: low ? Colors.red : null,
          fontWeight: low ? FontWeight.bold : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Classroom Ranking')),
      body: ListenableBuilder(
        listenable: dataService,
        builder: (context, _) {
          final ranked = dataService.rankedClassrooms;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Text('Red values are below 3.0 and need attention.'),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(16),
                  child: DataTable(
                    columns: [
                      const DataColumn(label: Text('Rank')),
                      const DataColumn(label: Text('Classroom')),
                      const DataColumn(label: Text('Overall'), numeric: true),
                      for (final f in factors)
                        DataColumn(label: Text(f), numeric: true),
                    ],
                    rows: [
                      for (var i = 0; i < ranked.length; i++)
                        _buildRow(i, ranked[i]),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  DataRow _buildRow(int index, Classroom room) {
    final score = dataService.averageScore(room.id);
    final averages = dataService.factorAverages(room.id);
    return DataRow(
      cells: [
        DataCell(Text('${index + 1}')),
        DataCell(Text(room.fullName)),
        DataCell(
          Text(
            score == null ? '-' : score.toStringAsFixed(2),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        for (final f in factors) _factorCell(averages[f]),
      ],
    );
  }
}
