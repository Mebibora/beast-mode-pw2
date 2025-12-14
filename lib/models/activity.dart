import 'package:cloud_firestore/cloud_firestore.dart';

class Activity {
  final String id;
  final String uid;
  final String type; // workout, journal, challenge_join, ...
  final String refId;
  final String visibility; // "public"
  final DateTime createdAt;
  final String? text;
  final String? mediaThumbUrl;
  final int likeCount;
  final int commentCount;

  Activity({
    required this.id,
    required this.uid,
    required this.type,
    required this.refId,
    required this.visibility,
    required this.createdAt,
    this.text,
    this.mediaThumbUrl,
    this.likeCount = 0,
    this.commentCount = 0,
  });

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'type': type,
    'refId': refId,
    'visibility': visibility,
    'createdAt': Timestamp.fromDate(createdAt),
    'text': text,
    'mediaThumbUrl': mediaThumbUrl,
    'likeCount': likeCount,
    'commentCount': commentCount,
  };

  static Activity fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Activity(
      id: doc.id,
      uid: data['uid'] as String,
      type: data['type'] as String,
      refId: data['refId'] as String,
      visibility: (data['visibility'] as String?) ?? 'public',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      text: data['text'] as String?,
      mediaThumbUrl: data['mediaThumbUrl'] as String?,
      likeCount: (data['likeCount'] as num?)?.toInt() ?? 0,
      commentCount: (data['commentCount'] as num?)?.toInt() ?? 0,
    );
  }
}
