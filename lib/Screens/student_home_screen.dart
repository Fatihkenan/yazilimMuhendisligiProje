// lib/screens/student_home_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';
import '../models/message_model.dart';
import 'login_screen.dart';
import 'announcement_detail_screen.dart';
import 'profile_screen.dart'; // Saib'in eklediği profil sayfası importu

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<String> _enrolledClassIds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchEnrolledClasses();
  }

  // --- ÖĞRENCİNİN SINIFLARINI GETİR (Gerçek Veri) ---
  Future<void> _fetchEnrolledClasses() async {
    final String currentUserId = _auth.currentUser!.uid;

    try {
      final snapshot = await _firestore
          .collection('classrooms')
          .where('studentIds', arrayContains: currentUserId)
          .get();

      setState(() {
        _enrolledClassIds = snapshot.docs.map((doc) => doc.id).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              // --- SAİB'İN HEADER KISMI (Profil Tıklaması Eklendi) ---
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(), // Yeni yazdığımız ProfileScreen'e gider
                        ),
                      ),
                      child: const CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, color: Color(0xFF6366F1), size: 28),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Merhaba, Öğrenci 👋',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          Text(
                            _auth.currentUser?.email?.split('@')[0].toUpperCase() ?? 'ÖĞRENCİ',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Stack(
                      children: [
                        Icon(Icons.notifications, color: Colors.white, size: 30),
                        // Bildirim noktası şimdilik statik, ileride geliştirilebilir
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Icon(Icons.circle, color: Colors.red, size: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // --- FİREBASE CANLI VERİ BAĞLANTISI ---
              Expanded(
                child: _isLoading
                    ? _buildShimmerLoading()
                    : _enrolledClassIds.isEmpty
                        ? _buildEmptyState()
                        : StreamBuilder<QuerySnapshot>(
                            stream: _firestore
                                .collection('announcements')
                                .where('classroomId', whereIn: _enrolledClassIds)
                                .orderBy('createdAt', descending: true)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return const Center(child: Text('Hata oluştu.'));
                              }
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return _buildShimmerLoading();
                              }

                              final docs = snapshot.data?.docs ?? [];
                              final totalAnnouncements = docs.length;

                              return Column(
                                children: [
                                  // --- SAİB'İN İSTATİSTİK KARTI (Gerçek Veriye Bağlandı!) ---
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
                                          _buildStat('$totalAnnouncements', 'Toplam'),
                                          Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.4)),
                                          _buildStat('0', 'Yeni'), // İleride okunma durumu eklenirse güncellenir
                                          Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.4)),
                                          _buildStat('$totalAnnouncements', 'Okundu'),
                                        ],
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // --- BEYAZ LİSTE ALANI ---
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
                                            child: Text(
                                              'Son Duyurular',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1F2937),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: docs.isEmpty
                                                ? const Center(child: Text('Sınıfınızda henüz duyuru yok.'))
                                                : ListView.builder(
                                                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                                    itemCount: docs.length,
                                                    itemBuilder: (context, index) {
                                                      final data = docs[index].data() as Map<String, dynamic>;
                                                      final message = MessageModel.fromMap(data, docs[index].id);
                                                      return _buildAnnouncementCard(message);
                                                    },
                                                  ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Saib'in İstatistik Kutusu
  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  // Belal'in Yükleme Efekti
  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 3,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 120,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  // Öğrenci Sınıfı Yoksa
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 80, color: Colors.white.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text('Henüz bir sınıfa kayıtlı değilsiniz.', style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  // Senin Yazdığın Gerçek Veri Çeken Duyuru Kartı
  Widget _buildAnnouncementCard(MessageModel message) {
    final dateStr = "${message.createdAt.day}/${message.createdAt.month}/${message.createdAt.year}";

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AnnouncementDetailScreen(
              title: message.title,
              content: message.content,
              date: dateStr,
              imageUrl: message.imageUrl,
              pdfUrl: message.pdfUrl,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.campaign, color: Color(0xFF6366F1), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(message.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1F2937))),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF9CA3AF)),
                            const SizedBox(width: 4),
                            Text(dateStr, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                message.content,
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (message.imageUrl != null || message.pdfUrl != null) ...[
                const Divider(height: 24),
                Row(
                  children: [
                    if (message.imageUrl != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.image, size: 18),
                          label: const Text('Görsel Eklendi', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF6366F1)),
                        ),
                      ),
                    if (message.imageUrl != null && message.pdfUrl != null) const SizedBox(width: 8),
                    if (message.pdfUrl != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.picture_as_pdf, size: 18),
                          label: const Text('PDF Eklendi', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF8B5CF6)),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
