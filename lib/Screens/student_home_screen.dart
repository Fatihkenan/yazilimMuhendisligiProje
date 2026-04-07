// lib/screens/student_home_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import 'login_screen.dart';

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

  // --- ÖĞRENCİNİN SINIFLARINI GETİR (İzolasyon) ---
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sınıflar yüklenemedi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
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
              // Header Kısmı
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        color: Color(0xFF6366F1),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Merhaba, Öğrenci 👋',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            _auth.currentUser?.email?.split('@')[0] ??
                                'Öğrenci',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.logout,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: _signOut,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Liste Kısmı
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
                          'Canlı Duyuru Akışı',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ),

                      // --- İŞTE BURASI CANLI VERİ (STREAM BUILDER) ---
                      Expanded(
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _enrolledClassIds.isEmpty
                            ? _buildEmptyState()
                            : StreamBuilder<QuerySnapshot>(
                                stream: _firestore
                                    .collection('announcements')
                                    .where(
                                      'classroomId',
                                      whereIn: _enrolledClassIds,
                                    )
                                    .orderBy('createdAt', descending: true)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasError) {
                                    return Center(
                                      child: Text('Hata: ${snapshot.error}'),
                                    );
                                  }
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }

                                  final docs = snapshot.data?.docs ?? [];

                                  if (docs.isEmpty) {
                                    return const Center(
                                      child: Text(
                                        'Sınıfınızda henüz duyuru yok.',
                                      ),
                                    );
                                  }

                                  return ListView.builder(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      0,
                                      16,
                                      16,
                                    ),
                                    itemCount: docs.length,
                                    itemBuilder: (context, index) {
                                      final data =
                                          docs[index].data()
                                              as Map<String, dynamic>;
                                      final message = MessageModel.fromMap(
                                        data,
                                        docs[index].id,
                                      );
                                      return _buildAnnouncementCard(message);
                                    },
                                  );
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

  // Öğrenci Hiçbir Sınıfta Değilse
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Henüz bir sınıfa kayıtlı değilsiniz.',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Sınıfa katılma (Join Class) rotası eklenecek
            },
            icon: const Icon(Icons.add),
            label: const Text('Sınıfa Katıl'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Tekil Duyuru Kartı (UI + Backend Verisi)
  Widget _buildAnnouncementCard(MessageModel message) {
    // Tarihi formatlayalım
    final dateStr =
        "${message.createdAt.day}/${message.createdAt.month}/${message.createdAt.year}";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
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
                  child: const Icon(
                    Icons.campaign,
                    color: Color(0xFF6366F1),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: Color(0xFF9CA3AF),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dateStr,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
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
            ),

            // Eğer Hoca Resim veya PDF eklemişse Butonları Göster
            if (message.imageUrl != null || message.pdfUrl != null) ...[
              const Divider(height: 24),
              Row(
                children: [
                  if (message.imageUrl != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Resmi tam ekran açma eklenebilir
                        },
                        icon: const Icon(Icons.image, size: 18),
                        label: const Text(
                          'Görsel',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF6366F1),
                        ),
                      ),
                    ),
                  if (message.imageUrl != null && message.pdfUrl != null)
                    const SizedBox(width: 8),
                  if (message.pdfUrl != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: PDF indirme eklenebilir
                        },
                        icon: const Icon(Icons.picture_as_pdf, size: 18),
                        label: const Text(
                          'PDF İndir',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF8B5CF6),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
