// lib/services/firestore_service.dart

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/classroom_model.dart';
import '../models/message_model.dart'; // Duyuru modeli eklendi

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- YARDIMCI FONKSİYON: 6 Haneli Rastgele Kod Üretici ---
  String _generateInviteCode() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'; // Sadece büyük harf ve rakam
    Random rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }

  // --- TASK 2: Sınıf Oluşturma ve Benzersiz Kod Atama ---
  Future<ClassroomModel> createClass({
    required String name,
    required String teacherId,
  }) async {
    String inviteCode = '';
    bool isUnique = false;

    // 1. ADIM: Benzersiz (Unique) Kod Bulana Kadar Döngüye Gir
    while (!isUnique) {
      inviteCode = _generateInviteCode();

      // Firestore'da 'classrooms' koleksiyonunda bu kod var mı diye bak
      final snapshot = await _firestore
          .collection('classrooms')
          .where('inviteCode', isEqualTo: inviteCode)
          .get();

      // Eğer sonuç boşsa (kimse kullanmıyorsa), kod benzersizdir!
      if (snapshot.docs.isEmpty) {
        isUnique = true;
      }
    }

    // 2. ADIM: Firestore'da yeni bir döküman referansı oluştur (ID almak için)
    final docRef = _firestore.collection('classrooms').doc();

    // 3. ADIM: Modeli Oluştur
    final newClass = ClassroomModel(
      id: docRef.id,
      name: name,
      teacherId: teacherId,
      inviteCode: inviteCode,
      studentIds: [],
    );

    // 4. ADIM: Veritabanına Yaz!
    await docRef.set(newClass.toMap());

    return newClass;
  }

  // --- TASK 3: Öğrencinin Sınıfa Katılması ---
  Future<void> joinClass({
    required String inviteCode,
    required String studentId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('classrooms')
          .where('inviteCode', isEqualTo: inviteCode.trim().toUpperCase())
          .get();

      if (snapshot.docs.isEmpty) {
        throw Exception('Geçersiz sınıf kodu! Lütfen kodu kontrol edin.');
      }

      final classroomDoc = snapshot.docs.first;

      await classroomDoc.reference.update({
        'studentIds': FieldValue.arrayUnion([studentId]),
      });
    } catch (e) {
      throw Exception('Sınıfa katılırken bir hata oluştu: $e');
    }
  }

  // --- SPRINT 4: Duyuruyu (Medya Linkleriyle) Firestore'a Kaydet ---
  Future<void> sendAnnouncement({
    required String classroomId,
    required String teacherId,
    required String title,
    required String content,
    String? imageUrl,
    String? pdfUrl,
  }) async {
    final docRef = _firestore.collection('announcements').doc();

    await docRef.set({
      'id': docRef.id,
      'classroomId': classroomId,
      'teacherId': teacherId,
      'title': title,
      'content': content,
      'createdAt':
          FieldValue.serverTimestamp(), // Sunucu saati ile garantili kayıt
      'imageUrl': imageUrl,
      'pdfUrl': pdfUrl,
    });
  }

  // --- SPRINT 4: Canlı Duyuru Akışı (Real-Time StreamBuilder İçin) ---
  Stream<List<MessageModel>> getAnnouncements(String classroomId) {
    return _firestore
        .collection('announcements')
        .where('classroomId', isEqualTo: classroomId)
        .orderBy('createdAt', descending: true) // En yeni duyuru en üstte
        .snapshots() // Değişiklikleri anlık dinler
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }
}
