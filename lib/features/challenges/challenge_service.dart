import 'package:cloud_firestore/cloud_firestore.dart';

class ChallengeService {
  final FirebaseFirestore _db;
  ChallengeService(this._db);

  /// Week starts Monday 00:00 local.
  DateTime _startOfWeek(DateTime now) {
    final local = DateTime(now.year, now.month, now.day);
    final diff = (local.weekday - DateTime.monday) % 7;
    return local.subtract(Duration(days: diff));
  }

  DateTime _endOfWeek(DateTime start) => start.add(const Duration(days: 7));

  /// Ensure a public weekly "Post Twice" challenge exists for the current week.
  /// Returns the challengeId.
  Future<String> ensureWeeklyPostTwiceChallenge({required String uid}) async {
    final now = DateTime.now();
    final weekStart = _startOfWeek(now);
    final weekEnd = _endOfWeek(weekStart);

    final query = await _db
        .collection('challenges')
        .where('goalType', isEqualTo: 'posts_per_week')
        .where('weekStart', isEqualTo: Timestamp.fromDate(weekStart))
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) return query.docs.first.id;

    final ref = _db.collection('challenges').doc();
    await ref.set({
      'title': 'Post Twice This Week',
      'goalType': 'posts_per_week',
      'goalTarget': 2,
      'weekStart': Timestamp.fromDate(weekStart),
      'weekEnd': Timestamp.fromDate(weekEnd),
      'visibility': 'public',
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': uid, 
    });

    return ref.id;
  }

  /// Join challenge
  Future<void> joinChallenge({required String challengeId, required String uid}) async {
    final memberRef = _db.collection('challenges').doc(challengeId).collection('members').doc(uid);
    await memberRef.set({
      'joinedAt': FieldValue.serverTimestamp(),
      'progress': 0,
      'completedAt': null,
    }, SetOptions(merge: true));
  }

  /// Stream member doc
  Stream<DocumentSnapshot<Map<String, dynamic>>> memberStream({
    required String challengeId,
    required String uid,
  }) {
    return _db.collection('challenges').doc(challengeId).collection('members').doc(uid).snapshots();
  }

  /// Count a feed activity toward the weekly challenge (idempotent via events/{activityId})
  Future<void> countActivityForWeeklyPostChallenge({
    required String challengeId,
    required String uid,
    required String activityId,
  }) async {
    final challengeRef = _db.collection('challenges').doc(challengeId);
    final memberRef = challengeRef.collection('members').doc(uid);
    final eventRef = memberRef.collection('events').doc(activityId);

    await _db.runTransaction((tx) async {
      final memberSnap = await tx.get(memberRef);
      if (!memberSnap.exists) return; // not joined

      final eventSnap = await tx.get(eventRef);
      if (eventSnap.exists) return; // already counted

      final currentProgress = ((memberSnap.data()?['progress'] ?? 0) as num).toInt();
      final nextProgress = currentProgress + 1;

      tx.set(eventRef, {'createdAt': FieldValue.serverTimestamp()});

      tx.update(memberRef, {
        'progress': nextProgress,
        'completedAt': nextProgress >= 2 ? FieldValue.serverTimestamp() : null,
      });
    });
  }
}
