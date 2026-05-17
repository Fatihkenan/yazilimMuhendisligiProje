import 'package:cloud_firestore/cloud_firestore.dart';

class ChannelModel {
  final String id;
  final String communityId;
  final String name;
  final String createdBy;
  final DateTime createdAt;

  ChannelModel({
    required this.id,
    required this.communityId,
    required this.name,
    required this.createdBy,
    required this.createdAt,
  });

  factory ChannelModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ChannelModel(
      id: documentId,
      communityId: map['communityId'] ?? '',
      name: map['name'] ?? '',
      createdBy: map['createdBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
