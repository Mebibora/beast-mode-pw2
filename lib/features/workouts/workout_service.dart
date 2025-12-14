import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/workout.dart';
import '../challenges/challenge_service.dart';

class WorkoutService {
  final FirebaseFirestore _db;
  final ChallengeService _challengeService;

  WorkoutService(this._db) : _challengeService = ChallengeService(_db);

  /// Logs a workout and posts it to the public activity feed by default.
  /// Also counts the created activity toward the weekly "Post Twice" challenge (if joined).
  Future<String> logWorkout({
    required String uid,
    required String type,
    required int durationMins,
    String? notes,
    String visibility = 'public',
  }) async {
    final now = DateTime.now();

    // 1) Create workout
    final workoutRef = _db.collection('workouts').doc();
    final workout = Workout(
      id: workoutRef.id,
      uid: uid,
      type: type,
      durationMins: durationMins,
      notes: notes,
      createdAt: now,
      visibility: visibility,
    );

    // 2) Create feed activity
    final activityRef = _db.collection('activities').doc();
    final trimmedNotes = notes?.trim();
    final activityData = <String, dynamic>{
      'uid': uid,
      'type': 'workout',
      'refId': workoutRef.id,
      'visibility': visibility,
      'createdAt': Timestamp.fromDate(now),

      // Optional text for the post
      'text': (trimmedNotes == null || trimmedNotes.isEmpty) ? null : trimmedNotes,

      // Journal thumbnail can go here later
      'mediaThumbUrl': null,

      'likeCount': 0,
      'commentCount': 0,
    };

    // 3) Batch write workout + activity
    final batch = _db.batch();
    batch.set(workoutRef, workout.toMap());
    batch.set(activityRef, activityData);
    await batch.commit();

    // 4) Weekly challenge integration (MVP)
    // Ensures the weekly challenge exists, then counts THIS activity
    // toward the challenge (if the user joined).
    try {
      final challengeId = await _challengeService.ensureWeeklyPostTwiceChallenge(uid: uid);
      await _challengeService.countActivityForWeeklyPostChallenge(
        challengeId: challengeId,
        uid: uid,
        activityId: activityRef.id,
      );
    } catch (_) {
      // Non-fatal: workout + feed post should still succeed even if challenge update fails.
    }

    return workoutRef.id;
  }
}
