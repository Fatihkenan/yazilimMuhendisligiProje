import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String channelId;
  final String senderId;
  final String senderName;
  final String content;
  final String? fileUrl; // PDF veya resim yüklersek buraya gelecek
  final List<String> readBy; // Sprint 5 için "Okundu/Anladım" listesi
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.channelId,
    required this.senderId,
    required this.senderName,
    required this.content,
    this.fileUrl,
    required this.readBy,
    required this.createdAt,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String documentId) {
    return MessageModel(
      id: documentId,
      channelId: map['channelId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? 'Bilinmeyen',
      content: map['content'] ?? '',
      fileUrl: map['fileUrl'],
      readBy: List<String>.from(map['readBy'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
