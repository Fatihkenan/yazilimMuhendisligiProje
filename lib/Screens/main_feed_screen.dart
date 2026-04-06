import 'package:flutter/material.dart';

class MainFeedScreen extends StatelessWidget {
  const MainFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ana Akış'),
        centerTitle: true,
      ),
      // Task 6: StreamBuilder kullanımı
      body: StreamBuilder<List<Map<String, String>>>(
        // محاكاة لبيانات قادمة من السيرفر
        stream: Stream.value([
          {"hoca": "Dr. Ahmet Yılmaz", "mesaj": "Arkadaşlar, vize sınavı konuları sisteme yüklendi."},
          {"hoca": "Asistan Elif Kaya", "mesaj": "Ödev teslimlerini yarın saat 17:00'ye kadar yapınız."},
          {"hoca": "Prof. Dr. Mehmet Demir", "mesaj": "Yarınki dersimiz konferans salonunda yapılacaktır."},
        ]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              var post = snapshot.data![index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.person, color: Colors.white)),
                          const SizedBox(width: 12),
                          Text(post['hoca']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(post['mesaj']!, style: const TextStyle(fontSize: 15)),
                      const Divider(height: 25),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(Icons.favorite_border, size: 20, color: Colors.grey),
                          SizedBox(width: 20),
                          Icon(Icons.comment_outlined, size: 20, color: Colors.grey),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}