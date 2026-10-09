import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/data_service.dart';
import '../utils/score_utils.dart';
import '../widgets/charts.dart';
import '../widgets/widgets.dart';
import 'rate_classroom_screen.dart';

/// Shows a classroom's overall score, per-factor averages, problem areas
/// and anonymous student feedback.
class ClassroomDetailScreen extends StatelessWidget {
  final Classroom classroom;

  const ClassroomDetailScreen({super.key, required this.classroom});

  @override
  Widget build(BuildContext context) {
    final isStudent = dataService.currentUser?.role == UserRole.student;

    return Scaffold(
      appBar: AppBar(title: Text(classroom.fullName)),
      floatingActionButton: isStudent
          ? FloatingActionButton.extended(
        icon: const Icon(Icons.star),
        label: const Text('Rate this room'),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RateClassroomScreen(classroom: classroom),
          ),
        ),
      )
          : null,
      body: ListenableBuilder(
        listenable: dataService,
        builder: (context, _) {
          final score = dataService.averageScore(classroom.id);
          final count = dataService.ratingsFor(classroom.id).length;
          final plural = count == 1 ? '' : 's';
          final problems = dataService.problemFactors(classroom.id);
          final comments = dataService.feedbackFor(classroom.id);
          final textTheme = Theme.of(context).textTheme;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            children: [
              Center(
                child: Column(
                  children: [
                    Text(
                      score == null
                          ? 'No ratings yet'
                          : '${score.toStringAsFixed(2)} / 5.00',
                      style: textTheme.headlineMedium,
                    ),
                    if (score != null)
                      Text(
                        classify(score),
                        style: TextStyle(fontSize: 18, color: scoreColor(score)),
                      ),
                    Text('Based on $count evaluation$plural'),
                  ],
                ),
              ),
              if (problems.isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(
                  color: Colors.orange.shade50,
                  child: ListTile(
                    leading: Icon(Icons.warning_amber, color: Colors.orange.shade800),
                    title: const Text('Needs attention'),
                    subtitle: Text(problems.join(', ')),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text('Category ratings', style: textTheme.titleLarge),
              const SizedBox(height: 8),
              FactorBars(averages: dataService.factorAverages(classroom.id)),
              const SizedBox(height: 16),
              Text('Score trend (last $trendDays days)', style: textTheme.titleLarge),
              const SizedBox(height: 8),
              TrendSection(
                pointsFor: (factor) => dataService.trendFor(classroom.id, factor: factor),
              ),
              const SizedBox(height: 16),
              Text('Student feedback', style: textTheme.titleLarge),
              if (comments.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('No feedback yet.'),
                ),
              for (final r in comments)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.chat_bubble_outline),
                  title: Text(r.comment),
                  subtitle: Text(formatDate(r.createdAt)),
                ),
            ],
          );
        },
      ),
    );
  }
}