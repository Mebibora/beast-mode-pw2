import 'package:cloud_firestore/cloud_firestore.dart';

class Workout {
  final String id;
  final String uid;
  final String type;
  final int durationMins;
  final String? notes;
  final DateTime createdAt;
  final String visibility; // "public" default

  Workout({
    required this.id,
    required this.uid,
    required this.type,
    required this.durationMins,
    required this.createdAt,
    required this.visibility,
    this.notes,
  });

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'type': type,
    'durationMins': durationMins,
    'notes': notes,
    'createdAt': Timestamp.fromDate(createdAt),
    'visibility': visibility,
  };

  static Workout fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Workout(
      id: doc.id,
      uid: data['uid'] as String,
      type: data['type'] as String,
      durationMins: (data['durationMins'] as num).toInt(),
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      visibility: (data['visibility'] as String?) ?? 'public',
    );
  }
}
