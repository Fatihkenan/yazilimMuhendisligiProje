// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. KAYIT OLMA VE FIRESTORE'A 'STUDENT' OLARAK KAYDETME
  Future<UserCredential?> registerUser({
    required String email,
    required String password,
    required String adSoyad,
    required String kurumKodu,
  }) async {
    try {
      // Firebase Auth'ta e-posta ve şifre ile kullanıcı oluştur
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Oluşan kullanıcının bilgilerini Firestore veritabanına 'users' koleksiyonuna yaz
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'adSoyad': adSoyad,
        'email': email,
        'kurumKodu': kurumKodu, // Senin o meşhur Multi-Tenancy anahtarın
        'role':
            'student', // Varsayılan rol (Admin sonradan 'teacher' yapabilir)
        'kayitTarihi': FieldValue.serverTimestamp(),
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Hata durumunda mesajı arayüze fırlat
      throw Exception(e.message);
    }
  }

  // 2. GİRİŞ YAPMA FONKSİYONU
  Future<UserCredential?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }
}
