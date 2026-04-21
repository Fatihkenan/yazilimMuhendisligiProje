// lib/models/message_model.dart

class MessageModel {
  final String id;
  final String classroomId;
  final String teacherId;
  final String title;
  final String content;
  final DateTime createdAt;
  final String? imageUrl;
  final String? pdfUrl;
  // SPRINT 5: "Anladım" butonuna basan öğrencilerin UID listesi
  final List<String> understoodBy;

  MessageModel({
    required this.id,
    required this.classroomId,
    required this.teacherId,
    required this.title,
    required this.content,
    required this.createdAt,
    this.imageUrl,
    this.pdfUrl,
    this.understoodBy = const [], // Varsayılan olarak boş liste
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String documentId) {
    return MessageModel(
      id: documentId,
      classroomId: map['classroomId'] ?? '',
      teacherId: map['teacherId'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
      imageUrl: map['imageUrl'],
      pdfUrl: map['pdfUrl'],
      // SPRINT 5: Firestore'daki dynamic diziyi Dart List<String> formatına çeviriyoruz
      understoodBy: List<String>.from(map['understoodBy'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'classroomId': classroomId,
      'teacherId': teacherId,
      'title': title,
      'content': content,
      'createdAt': createdAt,
      'imageUrl': imageUrl,
      'pdfUrl': pdfUrl,
      // SPRINT 5: Veritabanına öğrenci listesini yazıyoruz
      'understoodBy': understoodBy,
    };
  }
}
