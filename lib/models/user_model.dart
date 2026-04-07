// lib/models/user_model.dart

class UserModel {
  final String uid;
  final String email;
  final String adSoyad;
  final String kurumKodu;
  final String role; // 'student' veya 'teacher'

  UserModel({
    required this.uid,
    required this.email,
    required this.adSoyad,
    required this.kurumKodu,
    required this.role,
  });

  // Firestore'dan gelen veriyi (Map) Dart nesnesine çevirir
  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: documentId,
      email: map['email'] ?? '',
      adSoyad: map['adSoyad'] ?? '',
      kurumKodu: map['kurumKodu'] ?? '',
      role: map['role'] ?? 'student',
    );
  }

  // Dart nesnesini Firestore'a yazmak için Map'e çevirir
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'adSoyad': adSoyad,
      'kurumKodu': kurumKodu,
      'role': role,
    };
  }
}
