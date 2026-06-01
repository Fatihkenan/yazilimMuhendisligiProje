// ignore_for_file: curly_braces_in_flow_control_structures, deprecated_member_use, use_build_context_synchronously, unused_import

import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'welcome_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _firstNameCtrl = TextEditingController();
  final TextEditingController _lastNameCtrl = TextEditingController();
  final TextEditingController _bioCtrl = TextEditingController();

  String _email = '';
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final user = _auth.currentUser;
    if (user == null) return;
    _email = user.email ?? '';
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final d = doc.data() as Map<String, dynamic>;
        _firstNameCtrl.text = d['firstName'] ?? '';
        _lastNameCtrl.text = d['lastName'] ?? '';
        _bioCtrl.text = d['bio'] ?? '';
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _pickProfilePhoto() async {
    final result = await fp.FilePicker.platform.pickFiles(
      type: fp.FileType.image,
      withData: true,
    );

    if (result == null || result.files.first.bytes == null) return;

    final bytes = result.files.first.bytes!;

    if (bytes.lengthInBytes > 200 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fotoğraf 200 KB altında olmalı!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final base64 = base64Encode(bytes);

    await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
      'photoBase64': base64,
    });
    setState(() {});
  }

  Future<void> _save() async {
    if (_firstNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ad alanı boş bırakılamaz!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() => _isSaving = true);
    final user = _auth.currentUser!;
    final fn = _firstNameCtrl.text.trim();
    final ln = _lastNameCtrl.text.trim();
    final full = '$fn $ln'.trim();

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'firstName': fn,
        'lastName': ln,
        'fullName': full,
        'name': full,
        'adSoyad': full,
        'bio': _bioCtrl.text.trim(),
        'email': _email.toLowerCase(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await user.updateDisplayName(full);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil güncellendi ✅'),
            backgroundColor: Colors.green,
          ),
        );
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
    }
    setState(() => _isSaving = false);
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Çıkış Yap',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        content: const Text('Hesabınızdan çıkış yapmak istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              await _auth.signOut();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                (r) => false,
              );
            },
            child: const Text(
              'Çıkış Yap',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ─── دالة حذف الحساب ──────────────────────────────────────────
  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Hesabı Sil',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        content: const Text(
          'Hesabınızı ve tüm verilerinizi kalıcı olarak silmek istediğinize emin misiniz? Bu işlem kesinlikle geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx); // إغلاق نافذة التأكيد
              await _performAccountDeletion();
            },
            child: const Text(
              'Sil',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performAccountDeletion() async {
    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // حذف بيانات المستخدم من Firestore
        await _firestore.collection('users').doc(user.uid).delete();
        
        // حذف الحساب من Firebase Auth
        await user.delete();

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (r) => false,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        // فايربيز يطلب تسجيل الدخول مؤخراً لحذف الحساب لأسباب أمنية
        if (e.toString().contains('requires-recent-login')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Güvenlik nedeniyle hesabınızı silebilmek için uygulamadan çıkış yapıp tekrar giriş yapmanız gerekmektedir.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 6),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String firstName = _firstNameCtrl.text;
    final String initial =
        firstName.isNotEmpty ? firstName[0].toUpperCase() : _email.isNotEmpty ? _email[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
        title: const Text(
          'Profil & Ayarlar',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // ── Avatar Bölümü ────────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Column(
                      children: [
                        FutureBuilder<DocumentSnapshot>(
                          future: _firestore.collection('users').doc(_auth.currentUser!.uid).get(),
                          builder: (ctx, snap) {
                            final photo = (snap.data?.data() as Map<String, dynamic>?)?['photoBase64'];
                            return GestureDetector(
                              onTap: _pickProfilePhoto,
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 45,
                                    backgroundColor: const Color(0xFF4F46E5),
                                    backgroundImage: photo != null
                                        ? MemoryImage(base64Decode(photo)) : null,
                                    child: photo == null
                                        ? Text(initial, style: const TextStyle(
                                            color: Colors.white, fontSize: 38, fontWeight: FontWeight.bold))
                                        : null,
                                  ),
                                  Positioned(
                                    bottom: 0, right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF4F46E5),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        Text(
                          '${_firstNameCtrl.text} ${_lastNameCtrl.text}'.trim().isEmpty
                              ? 'İsimsiz Kullanıcı'
                              : '${_firstNameCtrl.text} ${_lastNameCtrl.text}'.trim(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _email,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Kişisel Bilgiler ────────────────────────────────
                        _sectionTitle('KİŞİSEL BİLGİLER'),
                        const SizedBox(height: 10),
                        _card(
                          children: [
                            _profileField(
                              _firstNameCtrl,
                              'Adınız',
                              Icons.person_outline,
                            ),
                            _divider(),
                            _profileField(
                              _lastNameCtrl,
                              'Soyadınız',
                              Icons.badge_outlined,
                            ),
                            _divider(),
                            _profileField(
                              _bioCtrl,
                              'Biyografi',
                              Icons.info_outline,
                              maxLines: 2,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Kaydet butonu
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F46E5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            onPressed: _isSaving ? null : _save,
                            child: _isSaving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Değişiklikleri Kaydet',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // ── Hesap Yönetimi ──────────────────────────────────
                        _sectionTitle('HESAP YÖNETİMİ'),
                        const SizedBox(height: 10),

                        // Uygulama hakkında
                        _card(
                          children: [
                            _actionTile(
                              icon: Icons.info_outline,
                              color: const Color(0xFF4F46E5),
                              title: 'Uygulama Hakkında',
                              subtitle: 'Odaksınıf v2.0 — Teams Edition',
                              onTap: () {
                                showAboutDialog(
                                  context: context,
                                  applicationName: 'Odaksınıf',
                                  applicationVersion: 'v2.0',
                                  applicationLegalese:
                                      'Teams-Inspired Edition\n© 2025 Odaksınıf',
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Çıkış Yap
                        _card(
                          children: [
                            _actionTile(
                              icon: Icons.logout,
                              color: Colors.orange,
                              title: 'Hesaptan Çıkış Yap',
                              subtitle: 'Güvenli çıkış',
                              onTap: _logout,
                              isDanger: false, // غيرناها للبرتقالي لأن الحذف سيكون الأحمر
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // ─── خيار حذف الحساب الجديد ───
                        _card(
                          children: [
                            _actionTile(
                              icon: Icons.person_remove_rounded,
                              color: Colors.red,
                              title: 'Hesabı Sil',
                              subtitle: 'Hesabı ve verileri kalıcı olarak sil',
                              onTap: _deleteAccount,
                              isDanger: true,
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String t) => Text(
    t,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: Colors.grey,
      letterSpacing: 1.2,
    ),
  );

  Widget _card({required List<Widget> children}) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.grey.shade100),
    ),
    child: Column(children: children),
  );

  Widget _divider() => Divider(
    height: 1,
    color: Colors.grey.shade100,
    indent: 52,
  );

  Widget _profileField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    int maxLines = 1,
  }) =>
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF4F46E5), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      );

  Widget _actionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDanger = false,
  }) =>
      ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDanger ? Colors.red : const Color(0xFF1F2937),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey.shade300,
          size: 14,
        ),
      );
}