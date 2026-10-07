import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../widgets/widgets.dart';
import 'ranking_screen.dart';

/// Student home: pick a classroom to view its scores or rate it.
class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a Classroom'),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard),
            tooltip: 'Classroom ranking',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RankingScreen()),
            ),
          ),
          const LogoutButton(),
        ],
      ),
      body: ListenableBuilder(
        listenable: dataService,
        builder: (context, _) {
          final name = dataService.currentUser?.name ?? 'Student';
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text('Hello, $name! Tap a classroom to see its scores or rate it.'),
              ),
              for (final room in dataService.classrooms)
                ClassroomTile(classroom: room),
            ],
          );
        },
      ),
    );
  }
}
