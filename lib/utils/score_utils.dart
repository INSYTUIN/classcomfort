import 'package:flutter/material.dart';

/// The six environmental factors students rate.
const List<String> factors = [
  'Temperature',
  'Lighting',
  'Noise',
  'Seating',
  'Ventilation',
  'Internet',
];

const Map<String, IconData> factorIcons = {
  'Temperature': Icons.thermostat,
  'Lighting': Icons.lightbulb,
  'Noise': Icons.volume_up,
  'Seating': Icons.event_seat,
  'Ventilation': Icons.air,
  'Internet': Icons.wifi,
};

const Map<int, String> ratingLabels = {
  1: 'Very Poor',
  2: 'Poor',
  3: 'Fair',
  4: 'Good',
  5: 'Excellent',
};

/// A factor whose average is below this value is flagged as a problem area.
const double problemThreshold = 3.0;
const int trendDays = 30;

/// Classroom Comfort Score = (sum of all factor ratings) / number of factors.
double calculateScore(Map<String, int> scores) {
  final total = scores.values.fold<int>(0, (sum, v) => sum + v);
  return total / scores.length;
}

/// Turns a score into a label (Excellent, Good, Fair, Poor, Very Poor).
String classify(double score) {
  if (score >= 4.5) return 'Excellent';
  if (score >= 3.5) return 'Good';
  if (score >= 2.5) return 'Fair';
  if (score >= 1.5) return 'Poor';
  return 'Very Poor';
}

Color scoreColor(double score) {
  if (score >= 4.5) return Colors.green.shade700;
  if (score >= 3.5) return Colors.lightGreen.shade700;
  if (score >= 2.5) return Colors.orange.shade800;
  return Colors.red.shade700;
}

String formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
