// lib/services/storage_service.dart

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // --- TASK: Dosyayı Firebase Storage'a Yükle ve Linkini Al ---
  Future<String> uploadFile(File file, String folderName) async {
    try {
      // Dosya adını benzersiz yapalım (Zaman damgası + rastgele sayı)
      String fileName =
          "${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}";

      // Storage referansı oluştur (Örn: announcements/1712500_resim.jpg)
      Reference ref = _storage.ref().child(folderName).child(fileName);

      // Dosyayı yükle
      UploadTask uploadTask = ref.putFile(file);

      // Yükleme durumunu takip etmek istersen burayı kullanabilirsin
      TaskSnapshot snapshot = await uploadTask;

      // İşlem bitince dosyanın internet üzerindeki linkini (URL) al
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception("Dosya yükleme hatası: $e");
    }
  }
}
