import 'package:flutter/material.dart';

class AnnouncementDetailScreen extends StatelessWidget {
  final String hocaName;
  final String message;

  const AnnouncementDetailScreen({super.key, required this.hocaName, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Duyuru Detayı')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            
            Image.network(
              'https://via.placeholder.com/600x400', 
              width: double.infinity, 
              height: 300, 
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hocaName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  Text(message, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 30),
                  
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('PDF indiriliyor...')),
                      );
                    },
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('PDF Dosyasını İndir'),
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