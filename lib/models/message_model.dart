// lib/models/message_model.dart

class MessageModel {
  final String id;
  final String classroomId;
  final String teacherId;
  final String title;
  final String content;
  final DateTime createdAt;
  final String? imageUrl; // Sprint 4: Medya özelliği eklendi
  final String? pdfUrl; // Sprint 4: Medya özelliği eklendi

  MessageModel({
    required this.id,
    required this.classroomId,
    required this.teacherId,
    required this.title,
    required this.content,
    required this.createdAt,
    this.imageUrl,
    this.pdfUrl,
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
      imageUrl: map['imageUrl'], // Veritabanından okuma
      pdfUrl: map['pdfUrl'], // Veritabanından okuma
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'classroomId': classroomId,
      'teacherId': teacherId,
      'title': title,
      'content': content,
      'createdAt': createdAt,
      'imageUrl': imageUrl, // Veritabanına yazma
      'pdfUrl': pdfUrl, // Veritabanına yazma
    };
  }
}
