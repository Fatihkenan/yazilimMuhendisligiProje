// lib/screens/join_class_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class JoinClassScreen extends StatefulWidget {
  const JoinClassScreen({super.key});

  @override
  State<JoinClassScreen> createState() => _JoinClassScreenState();
}

class _JoinClassScreenState extends State<JoinClassScreen> {
  final TextEditingController _codeController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  Future<void> _handleJoin() async {
    final enteredText = _codeController.text.trim();

    // 1. Boşluk kontrolü
    if (enteredText.isEmpty) {
      setState(() {
        _errorMessage = "Lütfen sınıf adını giriniz";
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

      // 2. Veritabanında sınıfı ara (Sınıf İsmine göre)
      final querySnapshot = await FirebaseFirestore.instance
          .collection('classrooms')
          .where('className', isEqualTo: enteredText)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        setState(() {
          _errorMessage = "Bu isimde bir sınıf bulunamadı!";
          _isLoading = false;
        });
        return;
      }

      final classDoc = querySnapshot.docs.first;
      final List<dynamic> currentStudents = classDoc.data()['studentIds'] ?? [];

      // 3. Öğrenci zaten bu sınıfa kayıtlı mı?
      if (currentStudents.contains(currentUserId)) {
        setState(() {
          _errorMessage = "Zaten bu sınıfa kayıtlısınız.";
          _isLoading = false;
        });
        return;
      }

      // 4. Öğrencinin UID'sini sınıfın studentIds listesine ekle
      await classDoc.reference.update({
        'studentIds': FieldValue.arrayUnion([currentUserId]),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sınıfa başarıyla katıldınız!'),
          backgroundColor: Colors.green,
        ),
      );

      // 5. Başarılı olunca geldiği ekrana (Ana sayfaya) geri dön
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _errorMessage = "Bir hata oluştu: $e";
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sınıfa Katıl')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Lütfen Sınıf Adını Giriniz',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _codeController,
              // maxLength ve klavye tipini kaldırdık ki harf de yazılabilsin
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: 'Örn: 12-A Yazılım',
                errorText: _errorMessage,
                counterText: "",
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, letterSpacing: 2),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleJoin,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Şimdi Katıl'),
            ),
          ],
        ),
      ),
    );
  }
}
