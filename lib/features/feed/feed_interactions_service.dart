import 'package:cloud_firestore/cloud_firestore.dart';

class FeedInteractionsService {
  final FirebaseFirestore _db;
  FeedInteractionsService(this._db);

  DocumentReference<Map<String, dynamic>> _activityRef(String activityId) =>
      _db.collection('activities').doc(activityId);

  /// Stream: did current user like this activity?
  Stream<bool> likedByMeStream({required String activityId, required String uid}) {
    return _activityRef(activityId)
        .collection('likes')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Future<void> like({required String activityId, required String uid}) async {
    final activityRef = _activityRef(activityId);
    final likeRef = activityRef.collection('likes').doc(uid);

    await _db.runTransaction((tx) async {
      final likeSnap = await tx.get(likeRef);
      if (likeSnap.exists) return; // already liked

      tx.set(likeRef, {'createdAt': FieldValue.serverTimestamp()});
      tx.update(activityRef, {'likeCount': FieldValue.increment(1)});
    });
  }

  Future<void> unlike({required String activityId, required String uid}) async {
    final activityRef = _activityRef(activityId);
    final likeRef = activityRef.collection('likes').doc(uid);

    await _db.runTransaction((tx) async {
      final likeSnap = await tx.get(likeRef);
      if (!likeSnap.exists) return; // already unliked

      tx.delete(likeRef);
      tx.update(activityRef, {'likeCount': FieldValue.increment(-1)});
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> commentsStream(String activityId, {int limit = 50}) {
    return _activityRef(activityId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  Future<void> addComment({
    required String activityId,
    required String uid,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final activityRef = _activityRef(activityId);
    final commentRef = activityRef.collection('comments').doc();

    await _db.runTransaction((tx) async {
      tx.set(commentRef, {
        'uid': uid,
        'text': trimmed,
        'createdAt': FieldValue.serverTimestamp(),
      });
      tx.update(activityRef, {'commentCount': FieldValue.increment(1)});
    });
  }

  Future<void> deleteComment({
    required String activityId,
    required String commentId,
  }) async {
    final activityRef = _activityRef(activityId);
    final commentRef = activityRef.collection('comments').doc(commentId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(commentRef);
      if (!snap.exists) return;

      tx.delete(commentRef);
      tx.update(activityRef, {'commentCount': FieldValue.increment(-1)});
    });
  }
}
