import 'package:flutter/material.dart';
import '../models/models.dart';
import '../screens/classroom_detail_screen.dart';
import '../screens/login_screen.dart';
import '../services/data_service.dart';
import '../utils/score_utils.dart';

/// Five tappable stars (1 to 5). A value of 0 means "not rated yet".
class RatingSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const RatingSelector({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final star = i + 1;
        return IconButton(
          iconSize: 36,
          color: Colors.amber.shade700,
          icon: Icon(star <= value ? Icons.star : Icons.star_border),
          onPressed: () => onChanged(star),
        );
      }),
    );
  }
}

/// Horizontal bars showing the average rating of each factor.
class FactorBars extends StatelessWidget {
  final Map<String, double> averages;

  const FactorBars({super.key, required this.averages});

  @override
  Widget build(BuildContext context) {
    if (averages.isEmpty) return const Text('No ratings yet.');
    return Column(
      children: [
        for (final entry in averages.entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(width: 100, child: Text(entry.key)),
                Expanded(
                  child: LinearProgressIndicator(
                    value: entry.value / 5,
                    minHeight: 10,
                    color: scoreColor(entry.value),
                    backgroundColor: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(width: 32, child: Text(entry.value.toStringAsFixed(1))),
              ],
            ),
          ),
      ],
    );
  }
}

/// Small colored box showing a classroom score (or "No ratings").
class ScoreBadge extends StatelessWidget {
  final double? score;

  const ScoreBadge({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final s = score;
    if (s == null) return const Text('No ratings');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scoreColor(s),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        s.toStringAsFixed(2),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// One classroom row. Tapping it opens the classroom's details.
class ClassroomTile extends StatelessWidget {
  final Classroom classroom;

  const ClassroomTile({super.key, required this.classroom});

  @override
  Widget build(BuildContext context) {
    final count = dataService.ratingsFor(classroom.id).length;
    final plural = count == 1 ? '' : 's';
    return Card(
      child: ListTile(
        leading: const Icon(Icons.meeting_room),
        title: Text(classroom.fullName),
        subtitle: Text('$count evaluation$plural'),
        trailing: ScoreBadge(score: dataService.averageScore(classroom.id)),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ClassroomDetailScreen(classroom: classroom),
          ),
        ),
      ),
    );
  }
}

/// App bar button that logs out and returns to the login screen.
class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.logout),
      tooltip: 'Log out',
      onPressed: () {
        dataService.logout();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      },
    );
  }
}
