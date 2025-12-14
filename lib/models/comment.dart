import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String uid;
  final String text;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.uid,
    required this.text,
    required this.createdAt,
  });

  static Comment fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Comment(
      id: doc.id,
      uid: data['uid'] as String,
      text: data['text'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
