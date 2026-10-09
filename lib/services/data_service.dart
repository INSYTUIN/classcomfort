import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../utils/score_utils.dart';

/// Stores and calculates all app data.
///
/// Classrooms and ratings are saved in Cloud Firestore. This class listens to
/// both collections and keeps a local copy, so every score calculation below
/// works exactly as before and the screens don't need to change.
///
/// Firestore layout:
///   users/{uid}      ->  role ('student' or 'admin')
///   classrooms/{id}  ->  building, roomNumber, capacity
///   ratings/{id}     ->  classroomId, userId, scores (map), comment, createdAt
class DataService extends ChangeNotifier {
  AppUser? _currentUser;

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  // ---------- Local copy of the Firestore data ----------

  final List<Classroom> _classrooms = [];
  final List<Rating> _ratings = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _classroomSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ratingSub;

  /// Called automatically after a successful login (never before, because the
  /// security rules only allow signed-in, verified users to read data).
  /// Whenever Firestore data changes, the local lists update and the
  /// screens rebuild automatically.
  void startListening() {
    _classroomSub ??= _db.collection('classrooms').snapshots().listen(
          (snapshot) {
        final list = snapshot.docs.map((doc) {
          final data = doc.data();
          return Classroom(
            id: doc.id,
            building: data['building'] as String? ?? '',
            roomNumber: data['roomNumber'] as String? ?? '',
            capacity: (data['capacity'] as num?)?.toInt() ?? 0,
          );
        }).toList()
          ..sort((a, b) => a.fullName.compareTo(b.fullName));

        _classrooms
          ..clear()
          ..addAll(list);
        notifyListeners();
      },
      onError: (Object e) => debugPrint('Classrooms listener error: $e'),
    );

    _ratingSub ??= _db.collection('ratings').snapshots().listen(
          (snapshot) {
        final list = snapshot.docs.map((doc) {
          final data = doc.data();
          final rawScores = (data['scores'] as Map?) ?? {};
          final created = data['createdAt'];
          return Rating(
            id: doc.id,
            classroomId: data['classroomId'] as String? ?? '',
            userId: data['userId'] as String? ?? '',
            scores: {
              for (final f in factors) f: (rawScores[f] as num?)?.toInt() ?? 0,
            },
            comment: data['comment'] as String? ?? '',
            createdAt: created is Timestamp ? created.toDate() : DateTime.now(),
          );
        }).toList();

        _ratings
          ..clear()
          ..addAll(list);
        notifyListeners();
      },
      onError: (Object e) => debugPrint('Ratings listener error: $e'),
    );
  }

  /// Stops syncing and clears the local copy (used when logging out).
  void stopListening() {
    _classroomSub?.cancel();
    _ratingSub?.cancel();
    _classroomSub = null;
    _ratingSub = null;
    _classrooms.clear();
    _ratings.clear();
  }

  // ---------- Authentication (Firebase Auth + role in Firestore) ----------

  /// If set (for example 'school.edu'), only emails ending in it can register.
  /// Leave empty to allow any email address.
  static const String allowedEmailDomain = '';

  FirebaseAuth get _auth => FirebaseAuth.instance;

  AppUser? get currentUser => _currentUser;

  /// Creates a STUDENT account and sends a verification email.
  /// Returns null on success, or an error message to show the user.
  Future<String?> register(String email, String password) async {
    final e = email.trim().toLowerCase();
    if (allowedEmailDomain.isNotEmpty && !e.endsWith('@$allowedEmailDomain')) {
      return 'Please use your school email (@$allowedEmailDomain).';
    }
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: e,
        password: password,
      );
      final user = cred.user!;
      await _db.collection('users').doc(user.uid).set({'role': 'student'});
      await user.sendEmailVerification();
      await _auth.signOut(); // they must verify, then log in
      return null;
    } on FirebaseAuthException catch (ex) {
      return _authMessage(ex);
    } catch (ex) {
      return 'Something went wrong: $ex';
    }
  }

  /// Logs in. Returns null on success, or an error message to show the user.
  Future<String?> login(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user!;

      if (!user.emailVerified) {
        await _auth.signOut();
        return 'Please verify your email first. Open the link we sent you, then log in.';
      }

      await _loadProfile(user);
      startListening();
      return null;
    } on FirebaseAuthException catch (ex) {
      return _authMessage(ex);
    } catch (ex) {
      return 'Something went wrong: $ex';
    }
  }

  /// Reads the user's role from Firestore (creating a student profile if it
  /// is missing) and sets [currentUser].
  Future<void> _loadProfile(User user) async {
    final profile = _db.collection('users').doc(user.uid);
    final snap = await profile.get();
    var role = 'student';
    if (snap.exists) {
      role = (snap.data()?['role'] as String?) ?? 'student';
    } else {
      await profile.set({'role': 'student'});
    }

    final email = user.email ?? '';
    _currentUser = AppUser(
      id: user.uid,
      name: email.split('@').first,
      email: email,
      role: role == 'admin' ? UserRole.admin : UserRole.student,
    );
  }

  /// Firebase keeps the user logged in on the device. Call this at startup:
  /// it returns true if someone is still logged in (and loads their role).
  Future<bool> restoreSession() async {
    final user = _auth.currentUser;
    if (user == null || !user.emailVerified) return false;
    try {
      await _loadProfile(user);
      startListening();
      return true;
    } catch (_) {
      return false; // e.g. offline: just show the login screen
    }
  }

  /// Sends a password reset email. Returns null on success, or an error message.
  Future<String?> sendPasswordReset(String email) async {
    final e = email.trim();
    if (e.isEmpty) return 'Type your email address first.';
    try {
      await _auth.sendPasswordResetEmail(email: e);
      return null;
    } on FirebaseAuthException catch (ex) {
      // Don't reveal whether an account exists for this email.
      if (ex.code == 'user-not-found') return null;
      return _authMessage(ex);
    } catch (ex) {
      return 'Something went wrong: $ex';
    }
  }

  Future<void> logout() async {
    stopListening();
    _currentUser = null;
    await _auth.signOut();
  }

  String _authMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Wrong email or password.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Something went wrong (${e.code}).';
    }
  }

  // ---------- Classrooms ----------

  List<Classroom> get classrooms => List.unmodifiable(_classrooms);

  Classroom classroomById(String id) => _classrooms.firstWhere((c) => c.id == id);

  /// Adds a classroom. Returns false if that building + room already exists.
  Future<bool> addClassroom({
    required String building,
    required String roomNumber,
    required int capacity,
  }) async {
    final exists = _classrooms.any((c) =>
    c.building.toLowerCase() == building.toLowerCase() &&
        c.roomNumber.toLowerCase() == roomNumber.toLowerCase());
    if (exists) return false;

    await _db.collection('classrooms').add({
      'building': building,
      'roomNumber': roomNumber,
      'capacity': capacity,
    });
    return true;
  }

  /// Removes a classroom together with all of its ratings and feedback.
  /// (A single batch can hold up to 500 deletes, plenty for now.)
  Future<void> removeClassroom(String id) async {
    final batch = _db.batch();
    batch.delete(_db.collection('classrooms').doc(id));
    for (final r in _ratings.where((r) => r.classroomId == id)) {
      batch.delete(_db.collection('ratings').doc(r.id));
    }
    await batch.commit();
  }

  // ---------- Ratings ----------

  List<Rating> ratingsFor(String classroomId) =>
      _ratings.where((r) => r.classroomId == classroomId).toList();

  /// Ratings whose classroom still exists. Used for campus-wide numbers so a
  /// half-finished delete never causes a crash.
  List<Rating> get _activeRatings {
    final ids = _classrooms.map((c) => c.id).toSet();
    return _ratings.where((r) => ids.contains(r.classroomId)).toList();
  }

  Future<void> submitRating({
    required String classroomId,
    required Map<String, int> scores,
    String comment = '',
  }) async {
    await _db.collection('ratings').add({
      'classroomId': classroomId,
      'userId': _currentUser?.id ?? 'unknown',
      'scores': scores,
      'comment': comment.trim(),
      'createdAt': Timestamp.now(),
    });
    // No notifyListeners() needed: the Firestore listener updates the screens.
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
      _withComments(_activeRatings).take(limit).toList();

  // ---------- Trends over time ----------

  /// Average score per day for the last [days] days. Days with no ratings are
  /// skipped. [factor] = null means the overall comfort score.
  List<TrendPoint> _dailyAverages(List<Rating> list, String? factor, int days) {
    final now = DateTime.now();
    final start = DateTime.utc(now.year, now.month, now.day - (days - 1));
    final byDay = <int, List<double>>{};

    for (final r in list) {
      final d = r.createdAt;
      final x = DateTime.utc(d.year, d.month, d.day).difference(start).inDays;
      if (x < 0 || x >= days) continue; // outside the chart window
      final value = factor == null ? r.overallScore : r.scores[factor]!.toDouble();
      byDay.putIfAbsent(x, () => []).add(value);
    }

    return byDay.entries
        .map((e) => TrendPoint(
      x: e.key,
      value: e.value.reduce((a, b) => a + b) / e.value.length,
    ))
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));
  }

  /// Daily trend for one classroom.
  List<TrendPoint> trendFor(String classroomId, {String? factor, int days = trendDays}) =>
      _dailyAverages(ratingsFor(classroomId), factor, days);

  /// Daily trend across all classrooms.
  List<TrendPoint> campusTrend({String? factor, int days = trendDays}) =>
      _dailyAverages(_activeRatings, factor, days);

  // ---------- Dashboard statistics ----------

  int get totalClassrooms => _classrooms.length;

  int get totalEvaluations => _activeRatings.length;

  double? get campusAverage {
    final list = _activeRatings;
    if (list.isEmpty) return null;
    return list.map((r) => r.overallScore).reduce((a, b) => a + b) / list.length;
  }

  Map<String, double> get campusFactorAverages =>
      _factorAveragesOf(_activeRatings);
}

/// One shared instance used by all screens.
final DataService dataService = DataService();