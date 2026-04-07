// lib/models/message_model.dart

class MessageModel {
  final String id;
  final String classroomId; // Bu duyuru hangi sınıfa atıldı?
  final String teacherId; // Hangi öğretmen attı?
  final String title;
  final String content;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.classroomId,
    required this.teacherId,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String documentId) {
    return MessageModel(
      id: documentId,
      classroomId: map['classroomId'] ?? '',
      teacherId: map['teacherId'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      // Firestore Timestamp objesini Dart DateTime'a çeviriyoruz
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'classroomId': classroomId,
      'teacherId': teacherId,
      'title': title,
      'content': content,
      'createdAt': createdAt,
    };
  }
}
