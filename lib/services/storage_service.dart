import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // --- DOSYAYI FİREBASE STORAGE'A YÜKLE VE LİNKİNİ AL ---
  Future<String> uploadMessageFile(File file, String channelId) async {
    try {
      // Dosya adı çakışmasın diye zaman damgası ekliyoruz
      String fileName =
          "${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}";

      // Dosyayı 'messages/KanalID/dosya_adi.pdf' şeklinde klasörlüyoruz
      Reference ref = _storage
          .ref()
          .child('messages')
          .child(channelId)
          .child(fileName);

      // Yüklemeyi başlat
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;

      // Yüklenen dosyanın indirme bağlantısını al (Bunu Firestore'a kaydedeceğiz)
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception("Dosya yükleme hatası: $e");
    }
  }
}
