// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. KAYIT OLMA VE FIRESTORE'A KAYDETME
  Future<UserCredential?> registerUser({
    required String email,
    required String password,
    required String adSoyad,
    required String kurumKodu,
    required String role, // YENİ EKLENDİ: Rol artık dışarıdan geliyor
  }) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'adSoyad': adSoyad,
        'email': email,
        'kurumKodu': kurumKodu,
        'role':
            role, // YENİ EKLENDİ: Arayüzden gelen rol veritabanına yazılıyor
        'kayitTarihi': FieldValue.serverTimestamp(),
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
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
