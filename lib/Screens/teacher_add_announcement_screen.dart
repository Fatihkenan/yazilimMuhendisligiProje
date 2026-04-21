// lib/screens/teacher_add_announcement_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/storage_service.dart';

class TeacherAddAnnouncementScreen extends StatefulWidget {
  const TeacherAddAnnouncementScreen({super.key});

  @override
  State<TeacherAddAnnouncementScreen> createState() =>
      _TeacherAddAnnouncementScreenState();
}

class _TeacherAddAnnouncementScreenState
    extends State<TeacherAddAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _titleFocus = FocusNode();
  final _contentFocus = FocusNode();

  bool _isLoading = false;
  bool _isLoadingClasses = true;

  File? _selectedImage;
  File? _selectedPdf;

  final StorageService _storageService = StorageService();

  // GERÇEK SINIFLARI TUTACAĞIMIZ LİSTE (Dummy veri silindi)
  List<Map<String, dynamic>> _myClasses = [];
  String? _selectedClassId;

  @override
  void initState() {
    super.initState();
    _fetchMyClasses(); // Sayfa açılırken hocanın sınıflarını çek
  }

  // --- ÖĞRETMENİN KENDİ SINIFLARINI FİREBASE'DEN ÇEK ---
  Future<void> _fetchMyClasses() async {
    try {
      final String uid = FirebaseAuth.instance.currentUser!.uid;
      final snapshot = await FirebaseFirestore.instance
          .collection('classrooms')
          .where('teacherId', isEqualTo: uid)
          .get();

      if (mounted) {
        setState(() {
          _myClasses = snapshot.docs
              .map((doc) => {'id': doc.id, 'name': doc['className']})
              .toList();
          _isLoadingClasses = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingClasses = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sınıflar yüklenemedi: $e')));
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocus.dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  // --- Resim Seçme ---
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  // --- PDF Seçme ---
  Future<void> _pickPdf() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      setState(() => _selectedPdf = File(result.files.single.path!));
    }
  }

  // --- DUYURUYU FİREBASE'E GÖNDER ---
  Future<void> _addAnnouncement() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      String? imageUrl;
      String? pdfUrl;
      final String teacherId = FirebaseAuth.instance.currentUser!.uid;

      // 1. Eğer Resim seçildiyse önce Storage'a yükle
      if (_selectedImage != null) {
        imageUrl = await _storageService.uploadFile(
          _selectedImage!,
          'announcement_images',
        );
      }

      // 2. Eğer PDF seçildiyse önce Storage'a yükle
      if (_selectedPdf != null) {
        pdfUrl = await _storageService.uploadFile(
          _selectedPdf!,
          'announcement_pdfs',
        );
      }

      // 3. DOĞRUDAN FIRESTORE'A YAZIYORUZ (Kusursuz eşleşme için)
      await FirebaseFirestore.instance.collection('announcements').add({
        'classroomId': _selectedClassId, // Öğrencinin dinlediği gerçek ID
        'teacherId': teacherId,
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'imageUrl': imageUrl,
        'pdfUrl': pdfUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Duyuru başarıyla paylaşıldı!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Yeni Duyuru Ekle',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _titleController,
                            focusNode: _titleFocus,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: 'Duyuru Başlığı',
                              prefixIcon: const Icon(Icons.title),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) =>
                                (value == null || value.isEmpty)
                                ? 'Başlık gerekli'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _contentController,
                            focusNode: _contentFocus,
                            maxLines: 4,
                            decoration: InputDecoration(
                              labelText: 'Duyuru İçeriği',
                              prefixIcon: const Icon(Icons.notes),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) =>
                                (value == null || value.isEmpty)
                                ? 'İçerik gerekli'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // DİNAMİK SINIF SEÇİCİ (FİREBASE'DEN GELENLER)
                          _isLoadingClasses
                              ? const CircularProgressIndicator()
                              : DropdownButtonFormField<String>(
                                  value: _selectedClassId,
                                  decoration: InputDecoration(
                                    labelText: 'Sınıf Seçin',
                                    prefixIcon: const Icon(Icons.class_),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  items: _myClasses.map((c) {
                                    return DropdownMenuItem<String>(
                                      value: c['id'], // Arka planda ID tutulur
                                      child: Text(
                                        c['name'],
                                      ), // Ekranda isim görünür
                                    );
                                  }).toList(),
                                  onChanged: (v) =>
                                      setState(() => _selectedClassId = v),
                                  validator: (v) => v == null
                                      ? 'Lütfen bir sınıf seçin'
                                      : null,
                                ),
                          const SizedBox(height: 24),

                          // --- DOSYA SEÇME BUTONLARI ---
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _pickImage,
                                  icon: const Icon(Icons.image),
                                  label: Text(
                                    _selectedImage == null
                                        ? 'Resim Ekle'
                                        : 'Resim Seçildi',
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF6366F1),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _pickPdf,
                                  icon: const Icon(Icons.picture_as_pdf),
                                  label: Text(
                                    _selectedPdf == null
                                        ? 'PDF Ekle'
                                        : 'PDF Seçildi',
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF8B5CF6),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _addAnnouncement,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      'Duyuruyu Gönder',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
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
}
