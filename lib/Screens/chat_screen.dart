// ignore_for_file: dead_code, curly_braces_in_flow_control_structures, use_build_context_synchronously, empty_catches, deprecated_member_use, unused_local_variable, unused_element

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:url_launcher/url_launcher.dart'; // نبقيه للويب فقط


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
  final FocusNode _messageFocus = FocusNode();

  bool _isAnnouncement = false;
  String _currentUserName = '';
  bool _isUploading = false;

  // ─── ميزات جديدة ─────────────────────────────────────────────
  Map<String, dynamic>? _replyingTo;
  String? _editingDocId;
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  // ─── DOSYA BOYUTU SINIRI: 700 KB
  static const int _maxFileSizeBytes = 700 * 1024;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserName();
  }

  Future<void> _loadCurrentUserName() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _currentUserName =
                data['fullName'] ??
                data['name'] ??
                data['adSoyad'] ??
                user.displayName ??
                _fallbackName(user.email);
          });
        }
      } else {
        if (mounted) {
          setState(() => _currentUserName =
              user.displayName ?? _fallbackName(user.email));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _currentUserName = _fallbackName(user.email));
      }
    }
  }

  String _fallbackName(String? email) {
    if (email == null) return 'Kullanıcı';
    final prefix = email.split('@')[0];
    if (prefix.length < 2) return 'Üye';
    return prefix[0].toUpperCase() + prefix.substring(1);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _titleController.dispose();
    _messageFocus.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  String _formatTime(Timestamp? ts) {
    if (ts == null) return '';
    final d = ts.toDate();
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inDays == 0) {
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Dün ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } else {
      return '${d.day}/${d.month} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
  }

  // ─── DOSYA İNDİR — Web + Android + iOS ───────────────────────
  Future<void> _downloadFile(String base64Data, String? fileName) async {
  try {
    final String fName = fileName ?? 'dosya';
    final Uint8List bytes = base64Decode(base64Data);

    // ─── ويب ───────────────────────────────────────────
    if (kIsWeb) {
      final String ext = fName.split('.').last.toLowerCase();
      String mimeType = 'application/octet-stream';
      if (ext == 'pdf')                         mimeType = 'application/pdf';
      else if (ext == 'png')                    mimeType = 'image/png';
      else if (['jpg','jpeg'].contains(ext))    mimeType = 'image/jpeg';
      else if (ext == 'webp')                   mimeType = 'image/webp';
      else if (ext == 'gif')                    mimeType = 'image/gif';
      else if (['doc','docx'].contains(ext))    mimeType = 'application/msword';
      else if (ext == 'txt')                    mimeType = 'text/plain';

      final uri = Uri.parse('data:$mimeType;base64,$base64Data');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
      return;
    }

    // ─── موبايل (Android & iOS) ────────────────────────
    final Directory tempDir = await getTemporaryDirectory();
    final String filePath = '${tempDir.path}/$fName';
    final File file = File(filePath);
    await file.writeAsBytes(bytes);

    final OpenResult result = await OpenFile.open(filePath);

    if (result.type != ResultType.done && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.type == ResultType.noAppToOpen
                ? 'Bu dosya türünü açacak uygulama bulunamadı'
                : 'Dosya açılamadı: ${result.message}',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }

  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

  // ─── DOSYA SEÇ & YÜKLE ───────────────────────────────────────
  Future<void> _pickFile() async {
    try {
      final result = await fp.FilePicker.platform.pickFiles(
        type: fp.FileType.any,
        withData: true,
      );

      if (result == null || result.files.first.bytes == null) return;

      final Uint8List bytes = result.files.first.bytes!;
      final String fileName = result.files.first.name;
      final int sizeInBytes = bytes.lengthInBytes;

      if (sizeInBytes > _maxFileSizeBytes) {
        if (mounted) {
          final sizeKB = (sizeInBytes / 1024).toStringAsFixed(0);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Dosya çok büyük! ($sizeKB KB)\nMaksimum: 700 KB',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red.shade700,
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      setState(() => _isUploading = true);
      final String base64Str = base64Encode(bytes);
      await _sendMessage(base64Data: base64Str, fileName: fileName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dosya seçim hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // ─── MESAJ GÖNDER ────────────────────────────────────────────
  Future<void> _sendMessage({String? base64Data, String? fileName}) async {
    final text = _messageController.text.trim();
    if (text.isEmpty && base64Data == null) {
      if (mounted) setState(() => _isUploading = false);
      return;
    }

    // تعديل رسالة موجودة
    if (_editingDocId != null) {
      await _firestore.collection('messages').doc(_editingDocId).update({
        'text': text,
        'edited': true,
      });
      if (mounted) setState(() { _editingDocId = null; _isUploading = false; });
      _messageController.clear();
      return;
    }

    if (_isAnnouncement && widget.isOwner && _titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Duyuru için başlık gerekli!'), backgroundColor: Colors.orange),
      );
      if (mounted) setState(() => _isUploading = false);
      return;
    }

    final user = _auth.currentUser;
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
            ? _titleController.text.trim().toUpperCase() : '',
        'base64Data': base64Data,
        'fileName': fileName,
        'replyTo': _replyingTo,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // تحديث unreadBy للأعضاء الآخرين
      final channelDoc = await _firestore
          .collection('channels').doc(widget.channelId).get();
      final commId = channelDoc.data()?['communityId'];
      if (commId != null) {
        final commDoc = await _firestore
            .collection('communities').doc(commId).get();
        final List<dynamic> members =
            List.from(commDoc.data()?['members'] ?? []);
        members.remove(user.uid);
        await _firestore.collection('channels').doc(widget.channelId).update({
          'unreadBy': members,
        });
      }

      // يكتب الآن — temizle
      _firestore.collection('typing').doc(widget.channelId).update({
        user.uid: FieldValue.delete(),
      }).catchError((_) {});

      _messageController.clear();
      _titleController.clear();
      if (mounted) setState(() {
        _isAnnouncement = false;
        _isUploading = false;
        _replyingTo = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')));
        setState(() => _isUploading = false);
      }
    }
  }

  // ─── يكتب الآن ───────────────────────────────────────────────
  void _onTyping() {
    final user = _auth.currentUser;
    if (user == null) return;
    _firestore.collection('typing').doc(widget.channelId).set({
      user.uid: {
        'name': _currentUserName,
        'at': FieldValue.serverTimestamp(),
      }
    }, SetOptions(merge: true));

    Future.delayed(const Duration(seconds: 3), () {
      _firestore.collection('typing').doc(widget.channelId).update({
        user.uid: FieldValue.delete(),
      }).catchError((_) {});
    });
  }

  // ─── Reactions ───────────────────────────────────────────────
  void _addReaction(String docId, String emoji) {
    final uid = _auth.currentUser?.uid ?? '';
    _firestore.collection('messages').doc(docId).update({
      'reactions.$emoji': FieldValue.arrayUnion([uid]),
    });
  }

  void _removeReaction(String docId, String emoji) {
    final uid = _auth.currentUser?.uid ?? '';
    _firestore.collection('messages').doc(docId).update({
      'reactions.$emoji': FieldValue.arrayRemove([uid]),
    });
  }

  void _showReactionPicker(String docId) {
    final emojis = ['👍', '❤️', '😂', '😮', '😢', '🎉'];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(16),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: emojis.map((e) => GestureDetector(
            onTap: () { Navigator.pop(ctx); _addReaction(docId, e); },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(e, style: const TextStyle(fontSize: 28)),
            ),
          )).toList(),
        ),
      ),
    );
  }

  void _showMessageOptions(String docId, Map data, bool isMe) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Reactions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['👍','❤️','😂','😮','😢','🎉'].map((e) =>
                  GestureDetector(
                    onTap: () { Navigator.pop(ctx); _addReaction(docId, e); },
                    child: Text(e, style: const TextStyle(fontSize: 30)),
                  ),
                ).toList(),
              ),
            ),
            const Divider(),
            // Reply
            ListTile(
              leading: const Icon(Icons.reply, color: Color(0xFF4F46E5)),
              title: const Text('Yanıtla'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _replyingTo = {
                  'text': data['text'] ?? '',
                  'senderName': data['senderName'] ?? '',
                  'docId': docId,
                });
              },
            ),
            // Pin — sadece owner
            if (widget.isOwner)
              ListTile(
                leading: const Icon(Icons.push_pin_outlined, color: Colors.orange),
                title: Text(data['pinned'] == true ? 'Sabitlemeyi Kaldır' : 'Sabitle'),
                onTap: () {
                  Navigator.pop(ctx);
                  _firestore.collection('messages').doc(docId).update({
                    'pinned': !(data['pinned'] == true),
                  });
                },
              ),
            // Edit — sadece kendi mesajın
            if (isMe)
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: Colors.blue),
                title: const Text('Düzenle'),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _editingDocId = docId;
                    _messageController.text = data['text'] ?? '';
                  });
                },
              ),
            // Delete
            if (isMe || widget.isOwner)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Sil', style: TextStyle(color: Colors.red)),
                onTap: () { Navigator.pop(ctx); _deleteMessage(docId); },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _deleteMessage(String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Mesajı Sil',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: const Text('Bu mesajı kalıcı olarak silmek istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await _firestore.collection('messages').doc(docId).delete();
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
                size: 18,
                color: widget.isReadOnly
                    ? Colors.orange
                    : const Color(0xFF4F46E5),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.channelName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.isReadOnly ? 'Duyuru Kanalı' : 'Genel Sohbet',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search,
                color: const Color(0xFF4F46E5)),
            onPressed: () => setState(() {
              _isSearching = !_isSearching;
              _searchQuery = '';
              _searchCtrl.clear();
            }),
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Sabitlenmiş mesaj banner ─────────────────────────
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('messages')
                .where('channelId', isEqualTo: widget.channelId)
                .where('pinned', isEqualTo: true)
                .limit(1)
                .snapshots(),
            builder: (ctx, snap) {
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) return const SizedBox();
              final text = (docs.first.data() as Map)['text'] ?? '';
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border(
                      bottom: BorderSide(color: Colors.orange.shade200)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.push_pin,
                        color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        text,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // ─── شريط البحث ──────────────────────────────────────
          if (_isSearching)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              color: Colors.white,
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                onChanged: (v) =>
                    setState(() => _searchQuery = v.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Mesajlarda ara...',
                  prefixIcon: const Icon(Icons.search,
                      color: Color(0xFF4F46E5)),
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),

          // ─── الرسائل ─────────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('messages')
                  .where('channelId', isEqualTo: widget.channelId)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (ctx, snap) {
                if (snap.hasError)
                  return const Center(child: Text('Bir hata oluştu.'));
                if (snap.connectionState == ConnectionState.waiting)
                  return const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF4F46E5)),
                  );

                final docs =
                    (snap.data?.docs ?? []).where((d) {
                  if (_searchQuery.isEmpty) return true;
                  final text = (d.data() as Map)['text']
                          ?.toString()
                          .toLowerCase() ??
                      '';
                  return text.contains(_searchQuery);
                }).toList();

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.isReadOnly
                              ? Icons.campaign_outlined
                              : Icons.chat_bubble_outline,
                          size: 56,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.isReadOnly
                              ? 'Henüz duyuru yok'
                              : 'Sohbeti başlatan ilk kişi ol!',
                          style:
                              TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 16,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final data =
                        docs[i].data() as Map<String, dynamic>;
                    final bool isMe =
                        data['senderId'] == _auth.currentUser?.uid;
                    final bool isAnn = data['type'] == 'announcement';
                    final bool canDelete = isMe || widget.isOwner;
                    final String senderName = data['senderName'] ??
                        data['senderEmail']
                            ?.toString()
                            .split('@')[0] ??
                        'Bilinmeyen';
                    final String timeStr = _formatTime(
                        data['createdAt'] as Timestamp?);
                    final bool isOwnerMsg =
                        data['senderId'] == widget.ownerId;
                    final String? base64 = data['base64Data'];
                    final String? fname = data['fileName'];
                    final bool isImg = fname != null &&
                        RegExp(
                          r'\.(jpg|jpeg|png|webp|gif)$',
                          caseSensitive: false,
                        ).hasMatch(fname);

                    if (isAnn) {
                      return _buildAnnouncementCard(
                        docs[i].id, data, senderName, timeStr,
                        isOwnerMsg, base64, fname, isImg, canDelete,
                      );
                    }
                    return _buildMessageBubble(
                      docs[i].id, data, isMe, senderName, timeStr,
                      isOwnerMsg, base64, fname, isImg, canDelete,
                    );
                  },
                );
              },
            ),
          ),

          // ─── يكتب الآن ───────────────────────────────────────
          StreamBuilder<DocumentSnapshot>(
            stream: _firestore
                .collection('typing')
                .doc(widget.channelId)
                .snapshots(),
            builder: (ctx, snap) {
              if (!snap.hasData || !snap.data!.exists)
                return const SizedBox();
              final data =
                  snap.data!.data() as Map<String, dynamic>? ?? {};
              final myUid = _auth.currentUser?.uid ?? '';
              final others = data.entries
                  .where((e) => e.key != myUid)
                  .toList();
              if (others.isEmpty) return const SizedBox();
              final names = others.map((e) {
                final v = e.value;
                return v is Map ? (v['name'] ?? 'Biri') : 'Biri';
              }).join(', ');
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 6),
                color: Colors.white,
                child: Row(
                  children: [
                    const _TypingDots(),
                    const SizedBox(width: 8),
                    Text(
                      '$names yazıyor...',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          if (canType)
            _buildInputBar()
          else
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade100,
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline,
                        color: Colors.grey, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Sadece yöneticiler mesaj atabilir',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
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

  // ─── DUYURU KARTI ────────────────────────────────────────────
  Widget _buildAnnouncementCard(
    String docId, Map data, String sender, String time,
    bool isOwnerMsg, String? base64, String? fname,
    bool isImg, bool canDelete,
  ) {
    return GestureDetector(
      onLongPress: () => _showMessageOptions(docId, data,
          data['senderId'] == _auth.currentUser?.uid),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
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
                Container(width: 5, color: const Color(0xFF6366F1)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius:
                                    BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.campaign,
                                  color: Colors.orange, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                data['title'] ?? 'ÖNEMLİ DUYURU',
                                style: const TextStyle(
                                  color: Color(0xFF1F2937),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Divider(height: 1),
                        ),
                        if (base64 != null)
                          _buildFileWidget(base64, fname, isImg, false),
                        if ((data['text'] ?? '').toString().isNotEmpty)
                          Text(
                            data['text'],
                            style: const TextStyle(
                              color: Color(0xFF4B5563),
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 11,
                              backgroundColor:
                                  const Color(0xFFEEF2FF),
                              child: Text(
                                sender[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFF4F46E5),
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                sender,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isOwnerMsg)
                              Container(
                                margin:
                                    const EdgeInsets.only(left: 4),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
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
                            const SizedBox(width: 8),
                            Text(
                              time,
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        if (data['reactions'] != null)
                          _buildReactions(
                              Map<String, dynamic>.from(
                                  data['reactions']),
                              docId),
                        if (data['edited'] == true)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '(düzenlendi)',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade400,
                                  fontStyle: FontStyle.italic),
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
      ),
    );
  }

  // ─── MESAJ BALONCUĞU ─────────────────────────────────────────
  Widget _buildMessageBubble(
    String docId, Map data, bool isMe, String sender, String time,
    bool isOwnerMsg, String? base64, String? fname,
    bool isImg, bool canDelete,
  ) {
    return GestureDetector(
      onLongPress: () => _showMessageOptions(docId, data, isMe),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment:
              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              CircleAvatar(
                radius: 15,
                backgroundColor: const Color(0xFFE0E7FF),
                child: Text(
                  sender[0].toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF4F46E5),
                    fontSize: 11,
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
                      padding:
                          const EdgeInsets.only(left: 4, bottom: 3),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              sender,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isOwnerMsg)
                            Container(
                              margin:
                                  const EdgeInsets.only(left: 5),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
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
                        base64 != null && isImg ? 4 : 12),
                    decoration: BoxDecoration(
                      color: isMe
                          ? const Color(0xFF4F46E5)
                          : Colors.white,
                      borderRadius:
                          BorderRadius.circular(16).copyWith(
                        bottomRight: isMe
                            ? const Radius.circular(4)
                            : const Radius.circular(16),
                        bottomLeft: !isMe
                            ? const Radius.circular(4)
                            : const Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 4,
                        ),
                      ],
                      border: isMe
                          ? null
                          : Border.all(
                              color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: isMe
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        // Reply göster
                        if (data['replyTo'] != null)
                          Container(
                            margin:
                                const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color:
                                  Colors.black.withOpacity(0.06),
                              borderRadius:
                                  BorderRadius.circular(8),
                              border: const Border(
                                  left: BorderSide(
                                      color: Color(0xFF4F46E5),
                                      width: 2)),
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['replyTo']['senderName'] ??
                                      '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11),
                                ),
                                Text(
                                  data['replyTo']['text'] ?? '',
                                  style: const TextStyle(
                                      fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                        if (base64 != null)
                          _buildFileWidget(
                              base64, fname, isImg, isMe),
                        if ((data['text'] ?? '')
                            .toString()
                            .isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(
                                top: base64 != null ? 6 : 0),
                            child: Text(
                              data['text'],
                              style: TextStyle(
                                color: isMe
                                    ? Colors.white
                                    : const Color(0xFF1F2937),
                                fontSize: 14,
                                height: 1.3,
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            time,
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
                  // Reactions
                  if (data['reactions'] != null)
                    _buildReactions(
                      Map<String, dynamic>.from(data['reactions']),
                      docId,
                    ),
                  // Edited işareti
                  if (data['edited'] == true)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '(düzenlendi)',
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade400,
                            fontStyle: FontStyle.italic),
                      ),
                    ),
                ],
              ),
            ),
            if (isMe) const SizedBox(width: 22),
          ],
        ),
      ),
    );
  }

  // ─── DOSYA/RESİM WİDGET ──────────────────────────────────────
  Widget _buildFileWidget(
      String base64, String? fname, bool isImg, bool isMe) {
    if (isImg) {
      return Stack(
        alignment: Alignment.bottomRight,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              base64Decode(base64),
              width: 200,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(6),
            child: GestureDetector(
              onTap: () => _downloadFile(base64, fname),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.download,
                    color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: () => _downloadFile(base64, fname ?? 'dosya'),
      child: Container(
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: isMe
              ? Colors.white.withOpacity(0.2)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insert_drive_file,
              color: isMe ? Colors.white : const Color(0xFF4F46E5),
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                fname ?? 'Dosya',
                style: TextStyle(
                  color: isMe
                      ? Colors.white
                      : const Color(0xFF4F46E5),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.download_rounded,
              color: isMe ? Colors.white : const Color(0xFF4F46E5),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReactions(
      Map<String, dynamic>? reactions, String docId) {
    if (reactions == null || reactions.isEmpty) return const SizedBox();
    final myUid = _auth.currentUser?.uid ?? '';
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        children: reactions.entries.map((e) {
          final List users = e.value as List;
          if (users.isEmpty) return const SizedBox();
          final bool iReacted = users.contains(myUid);
          return GestureDetector(
            onTap: () => iReacted
                ? _removeReaction(docId, e.key)
                : _addReaction(docId, e.key),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: iReacted
                    ? const Color(0xFFEEF2FF)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: iReacted
                      ? const Color(0xFF4F46E5)
                      : Colors.grey.shade200,
                ),
              ),
              child: Text(
                '${e.key} ${users.length}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── GİRİŞ ÇUBUĞU ────────────────────────────────────────────
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, -3),
          ),
        ],
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reply şeridi
            if (_replyingTo != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(10),
                  border: const Border(
                      left: BorderSide(
                          color: Color(0xFF4F46E5), width: 3)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _replyingTo!['senderName'] ?? '',
                            style: const TextStyle(
                              color: Color(0xFF4F46E5),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _replyingTo!['text'] ?? '',
                            style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _replyingTo = null),
                      child: const Icon(Icons.close,
                          size: 18, color: Colors.grey),
                    ),
                  ],
                ),
              ),

            if (widget.isOwner)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _toggleBtn('💬 Gönderi', !_isAnnouncement,
                          () {
                        setState(() {
                          _isAnnouncement = false;
                          _titleController.clear();
                        });
                      }),
                      _toggleBtn('📢 Duyuru', _isAnnouncement,
                          () {
                        setState(() => _isAnnouncement = true);
                      }),
                    ],
                  ),
                ),
              ),

            if (_isAnnouncement && widget.isOwner)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  controller: _titleController,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF1F2937),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Duyuru başlığı...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.normal,
                    ),
                    prefixIcon: const Icon(Icons.title,
                        color: Colors.orange, size: 18),
                    border: const UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Colors.orange),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(
                          color: Colors.orange, width: 2),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                          color: Colors.grey.shade300),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 8),
                    prefixIconConstraints:
                        const BoxConstraints(minWidth: 36),
                  ),
                ),
              ),

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: _isUploading ? null : _pickFile,
                  child: Container(
                    width: 42,
                    height: 42,
                    margin: const EdgeInsets.only(
                        right: 8, bottom: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.grey.shade200),
                    ),
                    child: _isUploading
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF4F46E5),
                            ),
                          )
                        : const Icon(Icons.attach_file,
                            color: Color(0xFF64748B), size: 20),
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                          color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      controller: _messageController,
                      focusNode: _messageFocus,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onChanged: (_) => _onTyping(),
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: _isAnnouncement
                            ? 'Duyuru içeriği...'
                            : 'Mesaj yaz...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 11,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _sendMessage(),
                  child: Container(
                    width: 44,
                    height: 44,
                    margin: const EdgeInsets.only(bottom: 1),
                    decoration: BoxDecoration(
                      color: _isAnnouncement
                          ? Colors.orange
                          : const Color(0xFF4F46E5),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_isAnnouncement
                                  ? Colors.orange
                                  : const Color(0xFF4F46E5))
                              .withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
            Padding(
              padding:
                  const EdgeInsets.only(top: 4, left: 52),
              child: Text(
                'Maks. 700 KB',
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade400),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggleBtn(
      String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active
                ? (_isAnnouncement && active
                    ? Colors.orange
                    : const Color(0xFF4F46E5))
                : Colors.grey.shade500,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// ─── Yazıyor animasyonu ───────────────────────────────────────────
class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _anim =
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Row(
        children: List.generate(
          3,
          (i) => Container(
            width: 6,
            height: 6,
            margin:
                const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}