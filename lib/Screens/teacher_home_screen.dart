// lib/screens/teacher_home_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'teacher_create_class_screen.dart';
import 'teacher_add_announcement_screen.dart';
import 'login_screen.dart'; // Çıkış yapınca buraya döneceğiz

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _teacherName = "YÜKLENİYOR...";

  @override
  void initState() {
    super.initState();
    _fetchTeacherData();
  }

  // --- ÖĞRETMENİN ADINI FİREBASE'DEN ÇEK ---
  Future<void> _fetchTeacherData() async {
    try {
      final String uid = _auth.currentUser!.uid;
      final doc = await _firestore.collection('users').doc(uid).get();

      if (doc.exists && mounted) {
        setState(() {
          _teacherName = (doc.data()?['adSoyad'] ?? "ÖĞRETMEN")
              .toString()
              .toUpperCase();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Ad yüklenemedi: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- GERÇEK FİREBASE ÇIKIŞ İŞLEMİ ---
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
              // Header
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
                            'Merhaba, Öğretmen 👋',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          // BURASI DİNAMİK OLDU
                          Text(
                            _teacherName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.notifications,
                      color: Colors.white,
                      size: 30,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Ana içerik
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        const Text(
                          'Öğretmen Paneli',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Ne yapmak istersiniz?',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // YAZ-35: Sınıf Oluştur kartı
                        _buildMenuCard(
                          context,
                          icon: Icons.class_,
                          title: 'Yeni Sınıf Oluştur',
                          subtitle: 'Öğrencileriniz için yeni bir sınıf açın',
                          color: const Color(0xFF6366F1),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const TeacherCreateClassScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // YAZ-36: Duyuru Ekle kartı
                        _buildMenuCard(
                          context,
                          icon: Icons.campaign,
                          title: 'Yeni Duyuru Ekle',
                          subtitle: 'Sınıflarınıza duyuru gönderin',
                          color: const Color(0xFF8B5CF6),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const TeacherAddAnnouncementScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Çıkış butonu (FİREBASE ÇIKIŞINA BAĞLANDI)
                        _buildMenuCard(
                          context,
                          icon: Icons.logout,
                          title: 'Çıkış Yap',
                          subtitle: 'Hesabınızdan güvenli çıkış yapın',
                          color: const Color(0xFFEF4444),
                          onTap: _signOut,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
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
      // MOUSE POINTER VE TIKLAMA EFEKTİ İÇİN MATERIAL & INKWELL EKLENDİ
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: color, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
