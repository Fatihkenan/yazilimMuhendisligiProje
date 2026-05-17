import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityModel {
  final String id;
  final String name;
  final String description;
  final String ownerId;
  final List<String> members;
  final List<String> allowedEmails;
  final DateTime createdAt;

  CommunityModel({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerId,
    required this.members,
    required this.allowedEmails,
    required this.createdAt,
  });

  factory CommunityModel.fromMap(Map<String, dynamic> map, String documentId) {
    return CommunityModel(
      id: documentId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      ownerId: map['ownerId'] ?? '',
      members: List<String>.from(map['members'] ?? []),
      allowedEmails: List<String>.from(map['allowedEmails'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
