// services/announcement_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createAnnouncement({
    required String title,
    required String content,
    required String classId,
    required String teacherId,
    required String teacherName,
  }) async {
    await _firestore.collection('messages').add({
      'title': title,
      'content': content,
      'classId': classId,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}