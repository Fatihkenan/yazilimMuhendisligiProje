import 'package:flutter/material.dart';

class AnnouncementDetailScreen extends StatelessWidget {
  final String title;
  final String content;
  final String date;
  final String? imageUrl;
  final String? pdfUrl;

  const AnnouncementDetailScreen({
    super.key,
    required this.title,
    required this.content,
    required this.date,
    this.imageUrl,
    this.pdfUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Duyuru Detayı'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resim varsa Firebase'den gelen gerçek resmi göster
            if (imageUrl != null)
              Image.network(
                imageUrl!,
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(
                    height: 300,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
              )
            // Resim yoksa standart bir kapak göster
            else
              Container(
                width: double.infinity,
                height: 200,
                color: const Color(0xFFEEF2FF),
                child: const Icon(Icons.campaign, size: 80, color: Color(0xFF6366F1)),
              ),
            
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Tarih: $date', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  const Divider(height: 30),
                  Text(
                    content,
                    style: const TextStyle(fontSize: 16, height: 1.5, color: Color(0xFF374151)),
                  ),
                  const SizedBox(height: 40),
                  
                  // Eğer PDF varsa indirme butonunu göster
                  if (pdfUrl != null)
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('PDF indirme işlemi başlatılıyor...')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('PDF Dosyasını İndir', style: TextStyle(fontSize: 16)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
