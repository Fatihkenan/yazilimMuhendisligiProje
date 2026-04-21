// lib/screens/main_feed_screen.dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
// Detay sayfasına geçişi kaldırdığımız için import'u sildik

class MainFeedScreen extends StatelessWidget {
  const MainFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ana Akış (Eski Taslak)'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, String>>>(
        stream: Stream.fromFuture(
          Future.delayed(
            const Duration(seconds: 2),
            () => [
              {
                "hoca": "Dr. Ahmet Yılmaz",
                "mesaj": "Arkadaşlar, vize sınavı konuları sisteme yüklendi.",
              },
              {
                "hoca": "Asistan Elif Kaya",
                "mesaj": "Ödev teslimlerini yarın saat 17:00'ye kadar yapınız.",
              },
              {
                "hoca": "Prof. Dr. Mehmet Demir",
                "mesaj": "Yarınki dersimiz konferans salonunda yapılacaktır.",
              },
            ],
          ),
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerLoading();
          }

          if (!snapshot.hasData)
            return const Center(child: Text("Veri bulunamadı"));

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              var post = snapshot.data![index];
              return InkWell(
                onTap: () {
                  // HATA BURADAYDI! Eski detay sayfasına geçmeye çalışıp çöküyordu.
                  // Artık burası kullanılmadığı için sadece uyarı veriyoruz.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Bu sayfa taslaktır. Lütfen gerçek öğrenci panelini kullanın.',
                      ),
                    ),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              post['hoca']!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          post['mesaj']!,
                          style: const TextStyle(fontSize: 15),
                        ),
                        const Divider(height: 25),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              Icons.favorite_border,
                              size: 20,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 5,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
