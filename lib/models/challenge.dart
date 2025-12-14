import 'package:cloud_firestore/cloud_firestore.dart';

class Challenge {
  final String id;
  final String title;
  final String goalType; // posts_per_week
  final int goalTarget;
  final DateTime weekStart;
  final DateTime weekEnd;

  Challenge({
    required this.id,
    required this.title,
    required this.goalType,
    required this.goalTarget,
    required this.weekStart,
    required this.weekEnd,
  });

  static Challenge fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Challenge(
      id: doc.id,
      title: data['title'] as String,
      goalType: data['goalType'] as String,
      goalTarget: (data['goalTarget'] as num).toInt(),
      weekStart: (data['weekStart'] as Timestamp).toDate(),
      weekEnd: (data['weekEnd'] as Timestamp).toDate(),
    );
  }
}
