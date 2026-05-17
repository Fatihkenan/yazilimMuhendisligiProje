import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String adSoyad;
  final String email;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.adSoyad,
    required this.email,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: documentId,
      adSoyad: map['adSoyad'] ?? '',
      email: map['email'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'adSoyad': adSoyad,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
