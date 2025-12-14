import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/activity.dart';

class FeedService {
  final FirebaseFirestore _db;
  FeedService(this._db);

  Stream<List<Activity>> publicFeedStream({int limit = 50}) {
    return _db
        .collection('activities')
        .where('visibility', isEqualTo: 'public')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Activity.fromDoc(d)).toList());
  }
}
