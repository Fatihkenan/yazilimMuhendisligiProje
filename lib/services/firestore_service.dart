// lib/services/firestore_service.dart

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/classroom_model.dart';

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

    // 3. ADIM: Modeli Oluştur (Task 1'de yazdığımız modeli kullanıyoruz)
    final newClass = ClassroomModel(
      id: docRef.id,
      name: name,
      teacherId: teacherId,
      inviteCode: inviteCode, // Garantili benzersiz kod
      studentIds: [], // Başlangıçta sınıf boş
    );

    // 4. ADIM: Veritabanına Yaz!
    await docRef.set(newClass.toMap());

    // İşlem bitince oluşturulan sınıfı geri döndür
    return newClass;
  }

  // --- TASK 3: Öğrencinin Sınıfa Katılması ---
  Future<void> joinClass({
    required String inviteCode,
    required String studentId,
  }) async {
    try {
      // 1. ADIM: Girilen kodu veritabanında ara
      final snapshot = await _firestore
          .collection('classrooms')
          .where('inviteCode', isEqualTo: inviteCode.trim().toUpperCase())
          .get();

      // 2. ADIM: Kod veritabanında yoksa hata fırlat
      if (snapshot.docs.isEmpty) {
        throw Exception('Geçersiz sınıf kodu! Lütfen kodu kontrol edin.');
      }

      // 3. ADIM: Sınıf bulunduysa dökümanı al
      final classroomDoc = snapshot.docs.first;

      // 4. ADIM: Öğrencinin UID'sini sınıfın studentIds listesine ekle
      // NOT: arrayUnion kullanıyoruz ki aynı öğrenci 2 kere eklenmesin!
      await classroomDoc.reference.update({
        'studentIds': FieldValue.arrayUnion([studentId]),
      });
    } catch (e) {
      // Hata mesajını UI tarafına fırlatıyoruz (SnackBar'da göstermek için)
      throw Exception('Sınıfa katılırken bir hata oluştu: $e');
    }
  }
}
