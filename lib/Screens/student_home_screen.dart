// student_home_screen.dart
import 'package:flutter/material.dart';
import 'package:yazilimmuhendislgiproje/Screens/profile_screen.dart';

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  static const List<Map<String, dynamic>> _announcements = [
    {
      'title': 'Matematik Sınavı Hakkında',
      'teacher': 'Ahmet Yılmaz',
      'subject': 'Matematik',
      'date': '3 Nisan 2025',
      'content': 'Yarınki sınav Bölüm 5 ve 6\'yı kapsayacaktır. Formülleri unutmayın.',
      'isNew': true,
      'color': Color(0xFF6366F1),
      'icon': Icons.calculate,
    },
    {
      'title': 'Proje Teslim Tarihi Uzatıldı',
      'teacher': 'Ayşe Kaya',
      'subject': 'Fizik',
      'date': '2 Nisan 2025',
      'content': 'Fizik projesi teslim tarihi 10 Nisan\'a uzatılmıştır.',
      'isNew': true,
      'color': Color(0xFF8B5CF6),
      'icon': Icons.science,
    },
    {
      'title': 'Okul Gezisi Duyurusu',
      'teacher': 'Mehmet Demir',
      'subject': 'Genel',
      'date': '1 Nisan 2025',
      'content': 'Bu ay 15\'inde Ankara gezisi düzenlenecektir. Velilerin onayı gereklidir.',
      'isNew': false,
      'color': Color(0xFF06B6D4),
      'icon': Icons.directions_bus,
    },
    {
      'title': 'Kütüphane Saatleri Değişti',
      'teacher': 'Fatma Şahin',
      'subject': 'Genel',
      'date': '28 Mart 2025',
      'content': 'Kütüphane artık 08:00 - 18:00 saatleri arasında açık olacaktır.',
      'isNew': false,
      'color': Color(0xFF10B981),
      'icon': Icons.menu_book,
    },
    {
      'title': 'Beden Eğitimi Dersi İptal',
      'teacher': 'Ali Çelik',
      'subject': 'Beden Eğitimi',
      'date': '27 Mart 2025',
      'content': 'Yarınki beden eğitimi dersi hava koşulları nedeniyle iptal edilmiştir.',
      'isNew': false,
      'color': Color(0xFFF59E0B),
      'icon': Icons.sports_soccer,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final newCount = _announcements.where((a) => a['isNew'] == true).length;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFA855F7)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // ← تعديل YAZ-38: الضغط على الأفاتار يفتح صفحة البروفيل
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(
                            userName: 'Ahmet Yıldız',
                            userEmail: 'ahmet@test.com',
                            kurumKodu: 'ODAK-001',
                          ),
                        ),
                      ),
                      child: const CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, color: Color(0xFF6366F1), size: 28),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Merhaba, Öğrenci 👋',
                              style: TextStyle(color: Colors.white70, fontSize: 14)),
                          Text('Ahmet Yıldız',
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Stack(
                      children: [
                        const Icon(Icons.notifications, color: Colors.white, size: 30),
                        if (newCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              child: Text('$newCount',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // İstatistik kartı
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat('${_announcements.length}', 'Toplam'),
                      Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.4)),
                      _buildStat('$newCount', 'Yeni'),
                      Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.4)),
                      _buildStat('${_announcements.length - newCount}', 'Okundu'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Liste
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                        child: Text('Son Duyurular',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: _announcements.length,
                          itemBuilder: (context, index) {
                            final a = _announcements[index];
                            return _buildAnnouncementCard(context, a);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildAnnouncementCard(BuildContext context, Map<String, dynamic> a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: (a['color'] as Color).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(a['icon'] as IconData, color: a['color'] as Color, size: 24),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(a['title'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1F2937))),
            ),
            if (a['isNew'] == true)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFF6366F1), borderRadius: BorderRadius.circular(20)),
                child: const Text('Yeni', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(a['content'], style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 14, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 4),
                Text(a['teacher'], style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                const SizedBox(width: 12),
                const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 4),
                Text(a['date'], style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}