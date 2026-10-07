import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/data_service.dart';
import '../utils/score_utils.dart';
import '../widgets/widgets.dart';

/// Students rate the six factors (1 to 5 stars) and may leave feedback.
class RateClassroomScreen extends StatefulWidget {
  final Classroom classroom;

  const RateClassroomScreen({super.key, required this.classroom});

  @override
  State<RateClassroomScreen> createState() => _RateClassroomScreenState();
}

class _RateClassroomScreenState extends State<RateClassroomScreen> {
  // 0 = not rated yet
  final Map<String, int> _scores = {for (final f in factors) f: 0};
  final _commentController = TextEditingController();

  bool get _allRated => _scores.values.every((v) => v > 0);

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submit() {
    dataService.submitRating(
      classroomId: widget.classroom.id,
      scores: Map.of(_scores),
      comment: _commentController.text,
    );
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      const SnackBar(content: Text('Thank you! Your rating was submitted.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Rate ${widget.classroom.fullName}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final factor in factors)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(factorIcons[factor]),
                        const SizedBox(width: 8),
                        Text(factor, style: Theme.of(context).textTheme.titleMedium),
                        const Spacer(),
                        Text(
                          _scores[factor]! > 0
                              ? ratingLabels[_scores[factor]]!
                              : 'Tap a star',
                        ),
                      ],
                    ),
                    RatingSelector(
                      value: _scores[factor]!,
                      onChanged: (v) => setState(() => _scores[factor] = v),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Feedback (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          if (_allRated)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Your score: ${calculateScore(_scores).toStringAsFixed(2)} / 5.00 '
                '(${classify(calculateScore(_scores))})',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          FilledButton(
            onPressed: _allRated ? _submit : null,
            child: const Text('Submit Rating'),
          ),
          if (!_allRated)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Please rate all six factors to submit.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }
}
