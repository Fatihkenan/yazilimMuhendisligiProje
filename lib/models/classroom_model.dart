// lib/models/classroom_model.dart

class ClassroomModel {
  final String id;
  final String name;
  final String teacherId;
  final String inviteCode; // 6 haneli kod
  final List<String> studentIds; // Sınıftaki öğrencilerin UID'leri

  ClassroomModel({
    required this.id,
    required this.name,
    required this.teacherId,
    required this.inviteCode,
    required this.studentIds,
  });

  factory ClassroomModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ClassroomModel(
      id: documentId,
      name: map['name'] ?? '',
      teacherId: map['teacherId'] ?? '',
      inviteCode: map['inviteCode'] ?? '',
      // Listeyi güvenli bir şekilde çekiyoruz
      studentIds: List<String>.from(map['studentIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'teacherId': teacherId,
      'inviteCode': inviteCode,
      'studentIds': studentIds,
    };
  }
}
