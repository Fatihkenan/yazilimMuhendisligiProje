import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:url_launcher/url_launcher.dart';

class ChatScreen extends StatefulWidget {
  final String channelId;
  final String channelName;
  final bool isReadOnly;
  final bool isOwner;
  final String ownerId;

  const ChatScreen({
    super.key,
    required this.channelId,
    required this.channelName,
    required this.isReadOnly,
    required this.isOwner,
    required this.ownerId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isAnnouncement = false;
  String _currentUserName = '';
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserName();
  }

  Future<void> _loadCurrentUserName() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data() as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              _currentUserName =
                  data['fullName'] ??
                  data['name'] ??
                  user.displayName ??
                  _generateFallbackName(user.email);
            });
          }
        } else {
          if (mounted) {
            setState(
              () => _currentUserName =
                  user.displayName ?? _generateFallbackName(user.email),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _currentUserName = _generateFallbackName(user.email));
        }
      }
    }
  }

  String _generateFallbackName(String? email) {
    if (email == null) return 'Kullanıcı';
    String prefix = email.split('@')[0];
    if (prefix.length < 3 || int.tryParse(prefix) != null) {
      return 'Üye $prefix';
    }
    return prefix[0].toUpperCase() + prefix.substring(1);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // --- EVRENSEL DOSYA İNDİRİCİ (HEM WEB HEM MOBİL UYUMLU) ---
  Future<void> _downloadFile(String base64Data, String fileName) async {
    try {
      String mimeType = 'application/octet-stream';
      final ext = fileName.split('.').last.toLowerCase();

      if (ext == 'pdf')
        mimeType = 'application/pdf';
      else if (ext == 'png')
        mimeType = 'image/png';
      else if (ext == 'jpg' || ext == 'jpeg')
        mimeType = 'image/jpeg';
      else if (ext == 'webp')
        mimeType = 'image/webp';

      // Base64 verisini evrensel bir Data URI'ye çeviriyoruz
      final Uri uri = Uri.parse('data:$mimeType;base64,$base64Data');

      // url_launcher paketi bunu hem tarayıcıda hem telefonda algılar
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dosya indirme tetiklenemedi.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İndirme hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- DOSYA/RESİM SEÇİCİ ---
  Future<void> _pickAndUploadFile() async {
    try {
      fp.FilePickerResult? result = await fp.FilePicker.platform.pickFiles(
        type: fp.FileType.any,
        withData: true,
      );

      if (result != null && result.files.first.bytes != null) {
        final Uint8List fileBytes = result.files.first.bytes!;
        final String fileName = result.files.first.name;

        if (fileBytes.lengthInBytes > 750000) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Dosya çok büyük! Lütfen 750 KB altı bir dosya seçin.',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        setState(() => _isUploading = true);

        String base64String = base64Encode(fileBytes);
        _sendMessage(base64Data: base64String, fileName: fileName);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Seçim hatası: $e')));
      setState(() => _isUploading = false);
    }
  }

  // --- MESAJ GÖNDERME ---
  void _sendMessage({String? base64Data, String? fileName}) async {
    final text = _messageController.text.trim();

    if (text.isEmpty && base64Data == null) {
      if (mounted) setState(() => _isUploading = false);
      return;
    }

    if (_isAnnouncement &&
        widget.isOwner &&
        _titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen duyuru için bir başlık girin!'),
          backgroundColor: Colors.orange,
        ),
      );
      if (mounted) setState(() => _isUploading = false);
      return;
    }

    final User? user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('messages').add({
        'channelId': widget.channelId,
        'text': text,
        'senderId': user.uid,
        'senderName': _currentUserName,
        'senderEmail': user.email,
        'type': _isAnnouncement && widget.isOwner ? 'announcement' : 'post',
        'title': _isAnnouncement && widget.isOwner
            ? _titleController.text.trim().toUpperCase()
            : '',
        'base64Data': base64Data,
        'fileName': fileName,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _messageController.clear();
      _titleController.clear();
      if (mounted) {
        setState(() {
          _isAnnouncement = false;
          _isUploading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
        setState(() => _isUploading = false);
      }
    }
  }

  void _deleteMessage(String docId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Mesajı Sil',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: const Text('Bu mesajı kalıcı olarak silmek istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _firestore.collection('messages').doc(docId).delete();
              } catch (e) {}
            },
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool canType = !widget.isReadOnly || widget.isOwner;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 1,
        shadowColor: Colors.black12,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.isReadOnly
                    ? Colors.orange.shade50
                    : const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                widget.isReadOnly ? Icons.campaign : Icons.tag,
                size: 20,
                color: widget.isReadOnly
                    ? Colors.orange
                    : const Color(0xFF4F46E5),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.channelName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                      fontSize: 18,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.isReadOnly ? 'Sadece Duyuru Kanalı' : 'Genel Sohbet',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('messages')
                  .where('channelId', isEqualTo: widget.channelId)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return const Center(child: Text('Bir hata oluştu.'));
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.isReadOnly
                              ? Icons.campaign_outlined
                              : Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.isReadOnly
                              ? 'Henüz duyuru yapılmadı.'
                              : 'Sohbeti başlatan ilk kişi olun!',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final bool isMe =
                        data['senderId'] == _auth.currentUser?.uid;
                    final bool isAnnouncement = data['type'] == 'announcement';
                    final bool canDelete = isMe || widget.isOwner;

                    final String displaySenderName =
                        data['senderName'] ??
                        data['senderEmail']?.toString().split('@')[0] ??
                        'Bilinmeyen';
                    final String timeStr = _formatTime(
                      data['createdAt'] as Timestamp?,
                    );
                    final bool isMessageOwner =
                        data['senderId'] == widget.ownerId;

                    final String? base64Data = data['base64Data'];
                    final String? fileName = data['fileName'];
                    final bool isImage =
                        fileName != null &&
                        (fileName.toLowerCase().endsWith('.jpg') ||
                            fileName.toLowerCase().endsWith('.png') ||
                            fileName.toLowerCase().endsWith('.jpeg') ||
                            fileName.toLowerCase().endsWith('.webp'));

                    // --- DUYURU KARTI ---
                    if (isAnnouncement) {
                      return GestureDetector(
                        onLongPress: canDelete
                            ? () => _deleteMessage(docs[index].id)
                            : null,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Container(
                                    width: 6,
                                    color: const Color(0xFF6366F1),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.orange.shade50,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: const Icon(
                                                  Icons.campaign,
                                                  color: Colors.orange,
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  data['title'] ??
                                                      'ÖNEMLİ DUYURU',
                                                  style: const TextStyle(
                                                    color: Color(0xFF1F2937),
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 16,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            child: Divider(height: 1),
                                          ),

                                          // İNDİRİLEBİLİR DOSYA/RESİM (DUYURU)
                                          if (base64Data != null)
                                            Container(
                                              margin: const EdgeInsets.only(
                                                bottom: 12,
                                              ),
                                              child: isImage
                                                  ? Stack(
                                                      alignment:
                                                          Alignment.bottomRight,
                                                      children: [
                                                        ClipRRect(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                          child: Image.memory(
                                                            base64Decode(
                                                              base64Data,
                                                            ),
                                                            fit: BoxFit.cover,
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets.all(
                                                                8.0,
                                                              ),
                                                          child: InkWell(
                                                            onTap: () =>
                                                                _downloadFile(
                                                                  base64Data,
                                                                  fileName ??
                                                                      'resim.png',
                                                                ),
                                                            child: Container(
                                                              padding:
                                                                  const EdgeInsets.all(
                                                                    8,
                                                                  ),
                                                              decoration:
                                                                  const BoxDecoration(
                                                                    color: Colors
                                                                        .black54,
                                                                    shape: BoxShape
                                                                        .circle,
                                                                  ),
                                                              child: const Icon(
                                                                Icons.download,
                                                                color: Colors
                                                                    .white,
                                                                size: 20,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    )
                                                  : InkWell(
                                                      onTap: () =>
                                                          _downloadFile(
                                                            base64Data,
                                                            fileName ?? 'dosya',
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.all(
                                                              12,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: Colors
                                                              .grey
                                                              .shade100,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                          border: Border.all(
                                                            color: Colors
                                                                .grey
                                                                .shade300,
                                                          ),
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            const Icon(
                                                              Icons
                                                                  .insert_drive_file,
                                                              color: Color(
                                                                0xFF4F46E5,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              width: 8,
                                                            ),
                                                            Expanded(
                                                              child: Text(
                                                                fileName ??
                                                                    'Ekli Dosya',
                                                                style: const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Color(
                                                                    0xFF4F46E5,
                                                                  ),
                                                                ),
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                            ),
                                                            const Icon(
                                                              Icons
                                                                  .download_rounded,
                                                              color: Color(
                                                                0xFF4F46E5,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                            ),

                                          if (data['text'] != null &&
                                              data['text']
                                                  .toString()
                                                  .isNotEmpty)
                                            Text(
                                              data['text'],
                                              style: const TextStyle(
                                                color: Color(0xFF4B5563),
                                                fontSize: 15,
                                                height: 1.5,
                                              ),
                                            ),
                                          const SizedBox(height: 16),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Row(
                                                  children: [
                                                    CircleAvatar(
                                                      radius: 12,
                                                      backgroundColor:
                                                          const Color(
                                                            0xFFEEF2FF,
                                                          ),
                                                      child: Text(
                                                        displaySenderName
                                                            .substring(0, 1)
                                                            .toUpperCase(),
                                                        style: const TextStyle(
                                                          color: Color(
                                                            0xFF4F46E5,
                                                          ),
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Flexible(
                                                      child: Text(
                                                        displaySenderName,
                                                        style: TextStyle(
                                                          color: Colors
                                                              .grey
                                                              .shade600,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                    if (isMessageOwner)
                                                      Container(
                                                        margin:
                                                            const EdgeInsets.only(
                                                              left: 6,
                                                            ),
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                              vertical: 2,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: Colors
                                                              .green
                                                              .shade50,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                4,
                                                              ),
                                                        ),
                                                        child: const Text(
                                                          'Kurucu',
                                                          style: TextStyle(
                                                            color: Colors.green,
                                                            fontSize: 9,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                timeStr,
                                                style: TextStyle(
                                                  color: Colors.grey.shade400,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    // --- NORMAL GÖNDERİ ---
                    return GestureDetector(
                      onLongPress: canDelete
                          ? () => _deleteMessage(docs[index].id)
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          mainAxisAlignment: isMe
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (!isMe) ...[
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: const Color(0xFFE0E7FF),
                                child: Text(
                                  displaySenderName
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    color: Color(0xFF4F46E5),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Column(
                                crossAxisAlignment: isMe
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  if (!isMe)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 4,
                                        bottom: 4,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              displaySenderName,
                                              style: TextStyle(
                                                color: Colors.grey.shade700,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (isMessageOwner)
                                            Container(
                                              margin: const EdgeInsets.only(
                                                left: 6,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 4,
                                                    vertical: 1,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.green.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                'Kurucu',
                                                style: TextStyle(
                                                  color: Colors.green,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  Container(
                                    padding: EdgeInsets.all(
                                      base64Data != null && isImage ? 4 : 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isMe
                                          ? const Color(0xFF4F46E5)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(18)
                                          .copyWith(
                                            bottomRight: isMe
                                                ? const Radius.circular(4)
                                                : const Radius.circular(18),
                                            bottomLeft: !isMe
                                                ? const Radius.circular(4)
                                                : const Radius.circular(18),
                                          ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.04),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                      border: isMe
                                          ? null
                                          : Border.all(
                                              color: Colors.grey.shade200,
                                            ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: isMe
                                          ? CrossAxisAlignment.end
                                          : CrossAxisAlignment.start,
                                      children: [
                                        // İNDİRİLEBİLİR DOSYA/RESİM (NORMAL MESAJ)
                                        if (base64Data != null)
                                          isImage
                                              ? Stack(
                                                  alignment:
                                                      Alignment.bottomRight,
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            14,
                                                          ),
                                                      child: Image.memory(
                                                        base64Decode(
                                                          base64Data,
                                                        ),
                                                        width: 200,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            6.0,
                                                          ),
                                                      child: InkWell(
                                                        onTap: () =>
                                                            _downloadFile(
                                                              base64Data,
                                                              fileName ??
                                                                  'resim.png',
                                                            ),
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets.all(
                                                                6,
                                                              ),
                                                          decoration:
                                                              const BoxDecoration(
                                                                color: Colors
                                                                    .black54,
                                                                shape: BoxShape
                                                                    .circle,
                                                              ),
                                                          child: const Icon(
                                                            Icons.download,
                                                            color: Colors.white,
                                                            size: 18,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              : InkWell(
                                                  onTap: () => _downloadFile(
                                                    base64Data,
                                                    fileName ?? 'dosya',
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          12,
                                                        ),
                                                    margin:
                                                        const EdgeInsets.only(
                                                          bottom: 8,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: isMe
                                                          ? Colors.white
                                                                .withOpacity(
                                                                  0.2,
                                                                )
                                                          : Colors
                                                                .grey
                                                                .shade100,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons
                                                              .insert_drive_file,
                                                          color: isMe
                                                              ? Colors.white
                                                              : const Color(
                                                                  0xFF4F46E5,
                                                                ),
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Flexible(
                                                          child: Text(
                                                            fileName ?? 'Dosya',
                                                            style: TextStyle(
                                                              color: isMe
                                                                  ? Colors.white
                                                                  : const Color(
                                                                      0xFF4F46E5,
                                                                    ),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Icon(
                                                          Icons
                                                              .download_rounded,
                                                          color: isMe
                                                              ? Colors.white
                                                              : const Color(
                                                                  0xFF4F46E5,
                                                                ),
                                                          size: 20,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),

                                        if (data['text'] != null &&
                                            data['text'].toString().isNotEmpty)
                                          Padding(
                                            padding: EdgeInsets.only(
                                              top: base64Data != null ? 8 : 0,
                                              left:
                                                  base64Data != null && isImage
                                                  ? 8
                                                  : 0,
                                              right:
                                                  base64Data != null && isImage
                                                  ? 8
                                                  : 0,
                                            ),
                                            child: Text(
                                              data['text'],
                                              style: TextStyle(
                                                color: isMe
                                                    ? Colors.white
                                                    : const Color(0xFF1F2937),
                                                fontSize: 15,
                                                height: 1.3,
                                              ),
                                            ),
                                          ),

                                        Padding(
                                          padding: EdgeInsets.only(
                                            top: 4,
                                            right: base64Data != null && isImage
                                                ? 8
                                                : 0,
                                          ),
                                          child: Text(
                                            timeStr,
                                            style: TextStyle(
                                              color: isMe
                                                  ? Colors.indigo.shade200
                                                  : Colors.grey.shade400,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isMe) const SizedBox(width: 24),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          if (canType)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.isOwner)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () => setState(() {
                                  _isAnnouncement = false;
                                  _titleController.clear();
                                }),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: !_isAnnouncement
                                        ? Colors.white
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: !_isAnnouncement
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.05,
                                              ),
                                              blurRadius: 4,
                                            ),
                                          ]
                                        : [],
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.chat_bubble_outline,
                                        size: 16,
                                        color: !_isAnnouncement
                                            ? const Color(0xFF4F46E5)
                                            : Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Gönderi',
                                        style: TextStyle(
                                          color: !_isAnnouncement
                                              ? const Color(0xFF4F46E5)
                                              : Colors.grey.shade600,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _isAnnouncement = true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _isAnnouncement
                                        ? Colors.white
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: _isAnnouncement
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.05,
                                              ),
                                              blurRadius: 4,
                                            ),
                                          ]
                                        : [],
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.campaign,
                                        size: 16,
                                        color: _isAnnouncement
                                            ? Colors.orange
                                            : Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Duyuru',
                                        style: TextStyle(
                                          color: _isAnnouncement
                                              ? Colors.orange
                                              : Colors.grey.shade600,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
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

                    if (_isAnnouncement && widget.isOwner)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: TextField(
                          controller: _titleController,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Duyuru Başlığı Ekleyin...',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontWeight: FontWeight.normal,
                            ),
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.orange,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 8,
                            ),
                            prefixIcon: const Icon(
                              Icons.title,
                              color: Colors.orange,
                              size: 20,
                            ),
                            prefixIconConstraints: const BoxConstraints(
                              minWidth: 40,
                            ),
                          ),
                        ),
                      ),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 8, bottom: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: IconButton(
                            icon: _isUploading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.attach_file,
                                    color: Color(0xFF64748B),
                                  ),
                            onPressed: _isUploading ? null : _pickAndUploadFile,
                            tooltip: 'Dosya veya Fotoğraf Yükle',
                          ),
                        ),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: TextField(
                              controller: _messageController,
                              minLines: 1,
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText: _isAnnouncement
                                    ? 'Duyuru detaylarını yazın...'
                                    : 'Mesaj yazın...',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade500,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          margin: const EdgeInsets.only(bottom: 2),
                          decoration: BoxDecoration(
                            color: _isAnnouncement
                                ? Colors.orange
                                : const Color(0xFF4F46E5),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (_isAnnouncement
                                            ? Colors.orange
                                            : const Color(0xFF4F46E5))
                                        .withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            onPressed: () => _sendMessage(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: const SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, color: Colors.grey, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Bu kanala sadece yöneticiler mesaj gönderebilir.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
