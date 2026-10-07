import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/data_service.dart';
import '../utils/score_utils.dart';
import '../widgets/widgets.dart';
import 'classroom_detail_screen.dart';
import 'manage_classrooms_screen.dart';
import 'ranking_screen.dart';

/// Basic admin dashboard: summary numbers, best/worst rooms,
/// weakest factors, rooms needing attention and recent feedback.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  void _openRoom(BuildContext context, Classroom room) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ClassroomDetailScreen(classroom: room)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: const [LogoutButton()],
      ),
      body: ListenableBuilder(
        listenable: dataService,
        builder: (context, _) {
          // Only rooms that have at least one rating
          final rated = dataService.rankedClassrooms
              .where((c) => dataService.averageScore(c.id) != null)
              .toList();
          final highest = rated.take(3).toList();
          final lowest = rated.reversed.take(3).toList();

          final campusAvg = dataService.campusAverage;

          // Campus-wide factor averages, weakest first
          final factorEntries = dataService.campusFactorAverages.entries.toList()
            ..sort((a, b) => a.value.compareTo(b.value));
          final weakestFactors = Map<String, double>.fromEntries(factorEntries);

          final needAttention = dataService.classrooms
              .where((c) => dataService.problemFactors(c.id).isNotEmpty)
              .toList();
          final feedback = dataService.recentFeedback();

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Classrooms',
                          value: '${dataService.totalClassrooms}',
                        ),
                      ),
                      Expanded(
                        child: _StatCard(
                          label: 'Evaluations',
                          value: '${dataService.totalEvaluations}',
                        ),
                      ),
                      Expanded(
                        child: _StatCard(
                          label: 'Campus Average',
                          value: campusAvg == null ? '-' : campusAvg.toStringAsFixed(2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        icon: const Icon(Icons.leaderboard),
                        label: const Text('Compare Classrooms'),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const RankingScreen()),
                        ),
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text('Manage Classrooms'),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ManageClassroomsScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const _SectionTitle('Highest-rated classrooms'),
                  for (final room in highest) ClassroomTile(classroom: room),
                  const _SectionTitle('Lowest-rated classrooms'),
                  for (final room in lowest) ClassroomTile(classroom: room),
                  const _SectionTitle('Lowest-rated factors (campus-wide)'),
                  FactorBars(averages: weakestFactors),
                  const _SectionTitle('Classrooms needing attention'),
                  if (needAttention.isEmpty) const Text('No problem areas detected.'),
                  for (final room in needAttention)
                    Card(
                      child: ListTile(
                        leading: Icon(Icons.warning_amber, color: Colors.orange.shade800),
                        title: Text(room.fullName),
                        subtitle: Text(
                          'Check: ${dataService.problemFactors(room.id).join(', ')}',
                        ),
                        onTap: () => _openRoom(context, room),
                      ),
                    ),
                  const _SectionTitle('Recent feedback'),
                  if (feedback.isEmpty) const Text('No feedback yet.'),
                  for (final r in feedback)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.chat_bubble_outline),
                      title: Text(r.comment),
                      subtitle: Text(
                        '${dataService.classroomById(r.classroomId).fullName}'
                            ' · ${formatDate(r.createdAt)}',
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}