import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../utils/score_utils.dart';

/// Stores and calculates all app data.
///
/// For now everything lives in memory (it resets when the app restarts).
/// Later, replace the lists in this file with Firebase Auth + Cloud Firestore
/// calls. The screens only talk to this class, so they won't need to change.
class DataService extends ChangeNotifier {
  DataService() {
    _seedSampleData();
  }

  int _nextId = 1;
  AppUser? _currentUser;

  // ---------- Demo data ----------

  final Map<String, String> _passwords = {
    'student@school.edu': '1234',
    'admin@school.edu': 'admin',
  };

  final List<AppUser> _users = [
    const AppUser(id: 'u1', name: 'Student', email: 'student@school.edu', role: UserRole.student),
    const AppUser(id: 'u2', name: 'Admin', email: 'admin@school.edu', role: UserRole.admin),
  ];

  final List<Classroom> _classrooms = [
    const Classroom(id: 'c1', building: 'Main Building', roomNumber: '103', capacity: 40),
    const Classroom(id: 'c2', building: 'Main Building', roomNumber: '105', capacity: 35),
    const Classroom(id: 'c3', building: 'Main Building', roomNumber: '201', capacity: 45),
    const Classroom(id: 'c4', building: 'Main Building', roomNumber: '204', capacity: 30),
    const Classroom(id: 'c5', building: 'Science Building', roomNumber: '301', capacity: 50),
  ];

  final List<Rating> _ratings = [];

  void _seedSampleData() {
    void add(String roomId, List<int> values, String comment, int daysAgo) {
      _ratings.add(Rating(
        id: '${_nextId++}',
        classroomId: roomId,
        userId: 'seed',
        scores: {for (var i = 0; i < factors.length; i++) factors[i]: values[i]},
        comment: comment,
        createdAt: DateTime.now().subtract(Duration(days: daysAgo)),
      ));
    }

    // Values are in this order: Temperature, Lighting, Noise, Seating, Ventilation, Internet
    add('c1', [4, 4, 2, 4, 3, 4], 'Very noisy hallway during class.', 1);
    add('c1', [5, 5, 3, 4, 2, 5], 'The room gets stuffy in the afternoon.', 3);
    add('c1', [4, 4, 3, 3, 3, 4], '', 5);
    add('c2', [4, 4, 4, 4, 4, 4], '', 2);
    add('c2', [4, 5, 4, 3, 4, 4], 'Nice and quiet.', 6);
    add('c3', [4, 5, 3, 4, 4, 5], 'Comfortable in the morning, but too warm in the afternoon.', 4);
    add('c3', [4, 4, 4, 4, 4, 4], '', 7);
    add('c4', [5, 5, 4, 4, 5, 4], 'Best room on campus.', 2);
    add('c4', [4, 5, 5, 4, 4, 5], '', 8);
    // Room 301 intentionally has no ratings yet.
  }

  // ---------- Authentication ----------

  AppUser? get currentUser => _currentUser;

  bool login(String email, String password) {
    final e = email.trim().toLowerCase();
    if (_passwords[e] != password) return false;
    _currentUser = _users.firstWhere((u) => u.email == e);
    return true;
  }

  void logout() {
    _currentUser = null;
  }

  // ---------- Classrooms ----------

  List<Classroom> get classrooms => List.unmodifiable(_classrooms);

  Classroom classroomById(String id) => _classrooms.firstWhere((c) => c.id == id);

  /// Adds a classroom. Returns false if that building + room already exists.
  bool addClassroom({
    required String building,
    required String roomNumber,
    required int capacity,
  }) {
    final exists = _classrooms.any((c) =>
    c.building.toLowerCase() == building.toLowerCase() &&
        c.roomNumber.toLowerCase() == roomNumber.toLowerCase());
    if (exists) return false;

    _classrooms.add(Classroom(
      id: 'c${_nextId++}',
      building: building,
      roomNumber: roomNumber,
      capacity: capacity,
    ));
    notifyListeners();
    return true;
  }

  /// Removes a classroom together with all of its ratings and feedback.
  void removeClassroom(String id) {
    _classrooms.removeWhere((c) => c.id == id);
    _ratings.removeWhere((r) => r.classroomId == id);
    notifyListeners();
  }

  // ---------- Ratings ----------

  List<Rating> ratingsFor(String classroomId) =>
      _ratings.where((r) => r.classroomId == classroomId).toList();

  void submitRating({
    required String classroomId,
    required Map<String, int> scores,
    String comment = '',
  }) {
    _ratings.add(Rating(
      id: '${_nextId++}',
      classroomId: classroomId,
      userId: _currentUser?.id ?? 'unknown',
      scores: scores,
      comment: comment.trim(),
      createdAt: DateTime.now(),
    ));
    notifyListeners(); // refreshes every screen that shows scores
  }

  // ---------- Scores and analysis ----------

  /// Average comfort score of a classroom, or null if it has no ratings.
  double? averageScore(String classroomId) {
    final list = ratingsFor(classroomId);
    if (list.isEmpty) return null;
    return list.map((r) => r.overallScore).reduce((a, b) => a + b) / list.length;
  }

  Map<String, double> _factorAveragesOf(List<Rating> list) {
    if (list.isEmpty) return {};
    return {
      for (final f in factors)
        f: list.map((r) => r.scores[f]!).reduce((a, b) => a + b) / list.length,
    };
  }

  /// Average rating per factor for one classroom (empty if no ratings).
  Map<String, double> factorAverages(String classroomId) =>
      _factorAveragesOf(ratingsFor(classroomId));

  /// Factors with an average below [problemThreshold], lowest first.
  /// This is the "Environmental Factor Analysis" feature.
  List<String> problemFactors(String classroomId) {
    final low = factorAverages(classroomId)
        .entries
        .where((e) => e.value < problemThreshold)
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return low.map((e) => e.key).toList();
  }

  /// Classrooms sorted from highest to lowest score (unrated ones last).
  List<Classroom> get rankedClassrooms {
    final list = List<Classroom>.of(_classrooms);
    list.sort((a, b) {
      final sa = averageScore(a.id);
      final sb = averageScore(b.id);
      if (sa == null && sb == null) return 0;
      if (sa == null) return 1;
      if (sb == null) return -1;
      return sb.compareTo(sa);
    });
    return list;
  }

  // ---------- Feedback ----------

  List<Rating> _withComments(Iterable<Rating> list) {
    return list.where((r) => r.comment.isNotEmpty).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<Rating> feedbackFor(String classroomId) =>
      _withComments(ratingsFor(classroomId));

  List<Rating> recentFeedback({int limit = 5}) =>
      _withComments(_ratings).take(limit).toList();

  // ---------- Dashboard statistics ----------

  int get totalClassrooms => _classrooms.length;

  int get totalEvaluations => _ratings.length;

  double? get campusAverage {
    if (_ratings.isEmpty) return null;
    return _ratings.map((r) => r.overallScore).reduce((a, b) => a + b) /
        _ratings.length;
  }

  Map<String, double> get campusFactorAverages => _factorAveragesOf(_ratings);
}

/// One shared instance used by all screens.
final DataService dataService = DataService();