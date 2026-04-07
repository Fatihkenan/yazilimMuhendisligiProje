// teacher_add_announcement_screen.dart
import 'package:flutter/material.dart';

class TeacherAddAnnouncementScreen extends StatefulWidget {
  const TeacherAddAnnouncementScreen({super.key});

  @override
  State<TeacherAddAnnouncementScreen> createState() => _TeacherAddAnnouncementScreenState();
}

class _TeacherAddAnnouncementScreenState extends State<TeacherAddAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _titleFocus = FocusNode();
  final _contentFocus = FocusNode();
  bool _isLoading = false;

  // Dummy sınıf listesi
  final List<String> _classes = [
    'YKS Sayısal-1',
    'YKS Sözel-2',
    'LGS Matematik',
    'LGS Fen Bilimleri',
    'KPSS Genel Kültür',
  ];
  String? _selectedClass;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocus.dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  Future<void> _addAnnouncement() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Duyuru başarıyla eklendi!'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
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
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(Icons.campaign, size: 44, color: Color(0xFF6366F1)),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'Duyuru Oluştur',
                                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Sınıfınıza duyuru gönderin',
                                style: TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
                              ),
                              const SizedBox(height: 32),

                              // Başlık
                              TextFormField(
                                controller: _titleController,
                                focusNode: _titleFocus,
                                textInputAction: TextInputAction.next,
                                onFieldSubmitted: (_) => _contentFocus.requestFocus(),
                                decoration: InputDecoration(
                                  labelText: 'Duyuru Başlığı',
                                  hintText: 'Örn: Sınav tarihi hakkında',
                                  prefixIcon: const Icon(Icons.title),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: const Color(0xFFF9FAFB),
                                ),
                                validator: (value) => (value == null || value.isEmpty)
                                    ? 'Başlık gerekli'
                                    : null,
                              ),
                              const SizedBox(height: 16),

                              // İçerik
                              TextFormField(
                                controller: _contentController,
                                focusNode: _contentFocus,
                                maxLines: 4,
                                textInputAction: TextInputAction.newline,
                                decoration: InputDecoration(
                                  labelText: 'Duyuru İçeriği',
                                  hintText: 'Duyurunuzun detaylarını buraya yazın...',
                                  prefixIcon: const Padding(
                                    padding: EdgeInsets.only(bottom: 60),
                                    child: Icon(Icons.notes),
                                  ),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: const Color(0xFFF9FAFB),
                                ),
                                validator: (value) => (value == null || value.isEmpty)
                                    ? 'İçerik gerekli'
                                    : null,
                              ),
                              const SizedBox(height: 16),

                              // Sınıf Dropdown
                              DropdownButtonFormField<String>(
                                // ignore: deprecated_member_use
                                value: _selectedClass,
                                decoration: InputDecoration(
                                  labelText: 'Sınıf Seçin',
                                  prefixIcon: const Icon(Icons.class_),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: const Color(0xFFF9FAFB),
                                ),
                                items: _classes.map((className) {
                                  return DropdownMenuItem(
                                    value: className,
                                    child: Text(className),
                                  );
                                }).toList(),
                                onChanged: (value) => setState(() => _selectedClass = value),
                                validator: (value) => value == null ? 'Lütfen bir sınıf seçin' : null,
                              ),
                              const SizedBox(height: 24),

                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _addAnnouncement,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6366F1),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 2,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        )
                                      : const Text('Duyuruyu Gönder', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ],
                          ),
                        ),
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