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
    
    
    bool isTeacher = true; 

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
                  const SizedBox(height: 30),
                  
                  
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('PDF Dosyasını İndir', style: TextStyle(fontSize: 16)),
                    ),

                  
                  if (isTeacher) ...[
                    const SizedBox(height: 40),
                    const Divider(thickness: 1.5),
                    const SizedBox(height: 10),
                    Row(
                      children: const [
                        Icon(Icons.analytics, color: Color(0xFF6366F1)),
                        SizedBox(width: 10),
                        Text(
                          "Okundu Raporu (Anladım)",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    _buildTeacherReportPanel(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  
  Widget _buildTeacherReportPanel() {
    
    final List<String> studentList = [
      "Ali Yılmaz",
      "Ayşe Kaya",
      "Mehmet Demir",
      "Fatma Çelik",
      "Caner Öz"
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: studentList.isEmpty
          ? const Text("Henüz kimse 'Anladım' butonuna basmadı.")
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: studentList.map((student) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 18),
                    const SizedBox(width: 10),
                    Text(student, style: const TextStyle(fontSize: 15, color: Color(0xFF4B5563))),
                  ],
                ),
              )).toList(),
            ),
    );
  }
}