import '../utils/score_utils.dart';

enum UserRole { student, admin }

class AppUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });
}

class Classroom {
  final String id;
  final String building;
  final String roomNumber;
  final int capacity;

  const Classroom({
    required this.id,
    required this.building,
    required this.roomNumber,
    required this.capacity,
  });

  String get fullName => '$building - Room $roomNumber';
}

class Rating {
  final String id;
  final String classroomId;
  final String userId;
  final Map<String, int> scores; // factor name -> 1 to 5
  final String comment; // optional student feedback ('' if none)
  final DateTime createdAt;

  const Rating({
    required this.id,
    required this.classroomId,
    required this.userId,
    required this.scores,
    required this.comment,
    required this.createdAt,
  });

  /// Classroom Comfort Score = sum of the 6 ratings / 6
  double get overallScore => calculateScore(scores);
}
