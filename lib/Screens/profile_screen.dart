// lib/screens/profile_screen.dart
import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart'; 
import 'welcome_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker(); 

  String userName = "Yükleniyor...";
  String userEmail = "Yükleniyor...";
  String kurumKodu = "Yükleniyor...";
  String? profileImageUrl; 
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // --- FİREBASE'DEN KULLANICI BİLGİLERİNİ ÇEKME ---
  Future<void> _fetchUserData() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      try {
        final DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          setState(() {
            userName = data['name'] ?? "Bilinmiyor";
            userEmail = user.email ?? "Bilinmiyor";
            kurumKodu = data['kurumKodu'] ?? "Tanımsız";
            profileImageUrl = data['profileImageUrl']; 
            isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          userName = "Hata oluştu";
          userEmail = user.email ?? "";
          kurumKodu = "-";
          isLoading = false;
        });
      }
    }
  }

  
  Future<void> _pickProfileImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60, 
    );

    if (image == null) return;

    final User? user = _auth.currentUser;
    if (user == null) return;

    try {
     
      await _firestore.collection('users').doc(user.uid).update({
        'profileImageUrl': image.path,
      });

      setState(() {
        profileImageUrl = image.path;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil resmi başarıyla güncellendi!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  
  void _showEditNameDialog() {
    final TextEditingController nameController = TextEditingController(text: userName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('İsmi Düzenle', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            hintText: "Yeni adınızı girin...",
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final String newName = nameController.text.trim();
              if (newName.isEmpty) return;

              final User? user = _auth.currentUser;
              if (user == null) return;

              try {
                await _firestore.collection('users').doc(user.uid).update({
                  'name': newName,
                });
                setState(() {
                  userName = newName;
                });
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Hata: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Kaydet'),
          ),
        ],
      ),
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
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Profil & Ayarlar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Avatar ve isim
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _pickProfileImage, 
                child: Stack(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: profileImageUrl != null
                            ? (profileImageUrl!.startsWith('http')
                                ? Image.network(profileImageUrl!, fit: BoxFit.cover, width: 90, height: 90)
                                : Image.file(File(profileImageUrl!), fit: BoxFit.cover, width: 90, height: 90))
                            : const Icon(
                                Icons.person,
                                size: 50,
                                color: Color(0xFF6366F1),
                              ),
                      ),
                    ),
                    
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, size: 18, color: Color(0xFF8B5CF6)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
              const SizedBox(height: 4),
              Text(
                userEmail,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),

              // İçerik kartları
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView(
                          padding: const EdgeInsets.all(20),
                          children: [
                            const SizedBox(height: 8),

                            // Bilgi kartı
                            _buildSectionTitle('Hesap Bilgileri'),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: _showEditNameDialog, 
                              child: _buildInfoCard(
                                icon: Icons.person_outline,
                                label: 'Ad Soyad (Düzenlemek için dokunun)',
                                value: userName,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildInfoCard(
                              icon: Icons.email_outlined,
                              label: 'E-posta',
                              value: userEmail,
                            ),
                            const SizedBox(height: 10),
                            _buildInfoCard(
                              icon: Icons.domain,
                              label: 'Kurum Kodu',
                              value: kurumKodu,
                              valueColor: const Color(0xFF6366F1),
                              valueBold: true,
                            ),
                            const SizedBox(height: 24),

                            // Ayarlar
                            _buildSectionTitle('Ayarlar'),
                            const SizedBox(height: 12),
                            _buildActionCard(
                              icon: Icons.notifications_outlined,
                              label: 'Bildirim Ayarları',
                              color: const Color(0xFF8B5CF6),
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Yakında eklenecek!'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 10),
                            _buildActionCard(
                              icon: Icons.lock_outline,
                              label: 'Şifre Değiştir',
                              color: const Color(0xFF06B6D4),
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Yakında eklenecek!'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 24),

                            // Çıkış butonu
                            _buildSectionTitle('Hesap'),
                            const SizedBox(height: 12),
                            _buildActionCard(
                              icon: Icons.logout,
                              label: 'Çıkış Yap',
                              color: const Color(0xFFEF4444),
                              onTap: () => _showLogoutDialog(context),
                            ),
                            const SizedBox(height: 20),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF9CA3AF),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    Color valueColor = const Color(0xFF1F2937),
    bool valueBold = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF6366F1), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    color: valueColor,
                    fontWeight: valueBold ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 14),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Çıkış Yap',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Hesabınızdançıkış yapmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'İptal',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await _auth.signOut();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }
}