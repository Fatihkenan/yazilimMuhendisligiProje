// ignore_for_file: use_build_context_synchronously, deprecated_member_use, curly_braces_in_flow_control_structures, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DMScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final String otherUserEmail;

  const DMScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserEmail,
  });

  @override
  State<DMScreen> createState() => _DMScreenState();
}

class _DMScreenState extends State<DMScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FocusNode _inputFocus = FocusNode();
  bool _isSending = false;

  Map<String, dynamic>? _replyingTo;
  String? _editingDocId;

  @override
  void initState() {
    super.initState();
    _markAsRead();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  Future<void> _markAsRead() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      await _firestore
          .collection('dm_conversations')
          .doc(widget.conversationId)
          .update({'unreadCount_$uid': 0});
    } catch (_) {}
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    if (_editingDocId != null) {
      await _firestore
          .collection('dm_conversations')
          .doc(widget.conversationId)
          .collection('messages')
          .doc(_editingDocId)
          .update({'text': text, 'edited': true});
      if (mounted) setState(() { _editingDocId = null; _isSending = false; });
      _msgCtrl.clear();
      return;
    }

    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isSending = true);
    _msgCtrl.clear();

    try {
      String senderName = user.displayName ?? user.email ?? 'Kullanıcı';
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final d = doc.data() as Map<String, dynamic>;
          senderName = d['fullName'] ?? d['name'] ?? senderName;
        }
      } catch (_) {}

      await _firestore
          .collection('dm_conversations')
          .doc(widget.conversationId)
          .collection('messages')
          .add({
        'text': text,
        'senderId': user.uid,
        'senderName': senderName,
        'replyTo': _replyingTo,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _firestore.collection('typing').doc(widget.conversationId).update({
        user.uid: FieldValue.delete(),
      }).catchError((_) {});

      await _firestore
          .collection('dm_conversations')
          .doc(widget.conversationId)
          .set({
        'lastMessage': text,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadCount_${widget.otherUserId}': FieldValue.increment(1),
        'participants': [user.uid, widget.otherUserId],
      }, SetOptions(merge: true));

      if (mounted) setState(() => _replyingTo = null);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mesaj gönderilemedi: $e'),
            backgroundColor: Colors.red,
          ),
        );
        _msgCtrl.text = text;
      }
    }

    if (mounted) setState(() => _isSending = false);
  }

  void _onTyping() {
    final user = _auth.currentUser;
    if (user == null) return;
    _firestore.collection('typing').doc(widget.conversationId).set({
      user.uid: {
        'name': user.displayName ?? 'Kullanıcı',
        'at': FieldValue.serverTimestamp(),
      }
    }, SetOptions(merge: true));

    Future.delayed(const Duration(seconds: 3), () {
      _firestore.collection('typing').doc(widget.conversationId).update({
        user.uid: FieldValue.delete(),
      }).catchError((_) {});
    });
  }

  void _addReaction(String docId, String emoji) {
    final uid = _auth.currentUser?.uid ?? '';
    _firestore
        .collection('dm_conversations')
        .doc(widget.conversationId)
        .collection('messages')
        .doc(docId)
        .update({
      'reactions.$emoji': FieldValue.arrayUnion([uid]),
    });
  }

  void _removeReaction(String docId, String emoji) {
    final uid = _auth.currentUser?.uid ?? '';
    _firestore
        .collection('dm_conversations')
        .doc(widget.conversationId)
        .collection('messages')
        .doc(docId)
        .update({
      'reactions.$emoji': FieldValue.arrayRemove([uid]),
    });
  }

  Widget _buildReactions(Map<String, dynamic>? reactions, String docId) {
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['👍', '❤️', '😂', '😮', '😢', '🎉'].map((e) =>
                  GestureDetector(
                    onTap: () { Navigator.pop(ctx); _addReaction(docId, e); },
                    child: Text(e, style: const TextStyle(fontSize: 30)),
                  ),
                ).toList(),
              ),
            ),
            const Divider(),
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
            if (isMe)
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: Colors.blue),
                title: const Text('Düzenle'),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _editingDocId = docId;
                    _msgCtrl.text = data['text'] ?? '';
                  });
                },
              ),
            if (isMe)
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

  void _deleteMessage(String msgId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Mesajı Sil',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text('Bu mesajı silmek istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await _firestore
                  .collection('dm_conversations')
                  .doc(widget.conversationId)
                  .collection('messages')
                  .doc(msgId)
                  .delete();
            },
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatTime(Timestamp? ts) {
    if (ts == null) return '';
    final d = ts.toDate();
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final String myUid = _auth.currentUser?.uid ?? '';
    final String initial = widget.otherUserName.isNotEmpty
        ? widget.otherUserName[0].toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 1,
        shadowColor: Colors.black12,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF4F46E5),
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1F2937),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.otherUserEmail,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
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
          // ─── Mesajlar ─────────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('dm_conversations')
                  .doc(widget.conversationId)
                  .collection('messages')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (ctx, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_off,
                            size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          'Bağlantı hatası, lütfen tekrar dene.',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }

                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF4F46E5),
                    ),
                  );
                }

                final docs = snap.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              initial,
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4F46E5),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.otherUserName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Konuşmayı sen başlat! 👋',
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
                  itemBuilder: (ctx, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final bool isMe = data['senderId'] == myUid;
                    final String time = _formatTime(data['createdAt'] as Timestamp?);

                    return GestureDetector(
                      onLongPress: () => _showMessageOptions(docs[i].id, data, isMe),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: isMe
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (!isMe) ...[
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: const Color(0xFFEEF2FF),
                                child: Text(
                                  initial,
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
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
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
                                      : Border.all(color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: isMe
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    if (data['replyTo'] != null)
                                      Container(
                                        margin: const EdgeInsets.only(bottom: 6),
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.06),
                                          borderRadius: BorderRadius.circular(8),
                                          border: const Border(left: BorderSide(color: Color(0xFF4F46E5), width: 2)),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              data['replyTo']['senderName'] ?? '',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isMe ? Colors.white : Colors.black87),
                                            ),
                                            Text(
                                              data['replyTo']['text'] ?? '',
                                              style: TextStyle(fontSize: 11, color: isMe ? Colors.white70 : Colors.black54),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    Text(
                                      data['text'] ?? '',
                                      style: TextStyle(
                                        color: isMe
                                            ? Colors.white
                                            : const Color(0xFF1F2937),
                                        fontSize: 15,
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      time,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isMe
                                            ? Colors.indigo.shade200
                                            : Colors.grey.shade400,
                                      ),
                                    ),
                                    if (data['reactions'] != null)
                                      _buildReactions(Map<String, dynamic>.from(data['reactions']), docs[i].id),
                                    if (data['edited'] == true)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          '(düzenlendi)',
                                          style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.grey.shade400, fontStyle: FontStyle.italic),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            if (isMe) const SizedBox(width: 22),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          StreamBuilder<DocumentSnapshot>(
            stream: _firestore.collection('typing').doc(widget.conversationId).snapshots(),
            builder: (ctx, snap) {
              if (!snap.hasData || !snap.data!.exists) return const SizedBox();
              final data = snap.data!.data() as Map<String, dynamic>? ?? {};
              final myUid = _auth.currentUser?.uid ?? '';
              final others = data.entries.where((e) => e.key != myUid).toList();
              if (others.isEmpty) return const SizedBox();
              final names = others.map((e) {
                final v = e.value;
                return v is Map ? (v['name'] ?? 'Biri') : 'Biri';
              }).join(', ');
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                color: Colors.white,
                child: Row(
                  children: [
                    _TypingDots(),
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

          // ─── Mesaj Kutusu ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, -3),
                ),
              ],
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_replyingTo != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(10),
                        border: const Border(left: BorderSide(color: Color(0xFF4F46E5), width: 3)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _replyingTo!['senderName'] ?? '',
                                  style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                Text(
                                  _replyingTo!['text'] ?? '',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _replyingTo = null),
                            child: const Icon(Icons.close, size: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: TextField(
                            controller: _msgCtrl,
                            focusNode: _inputFocus,
                            minLines: 1,
                            maxLines: 4,
                            textInputAction: TextInputAction.send,
                            onChanged: (_) => _onTyping(),
                            onSubmitted: (_) => _sendMessage(),
                            decoration: InputDecoration(
                              hintText: '${widget.otherUserName} ile mesajlaş...',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _isSending ? null : _sendMessage,
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: _isSending
                                ? Colors.grey.shade300
                                : const Color(0xFF4F46E5),
                            shape: BoxShape.circle,
                            boxShadow: _isSending
                                ? []
                                : [
                                    BoxShadow(
                                      color: const Color(0xFF4F46E5)
                                          .withOpacity(0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                          ),
                          child: _isSending
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.send_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
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
    );
  }
}

class _TypingDots extends StatefulWidget {
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
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Row(
        children: List.generate(3, (i) => Container(
          width: 6, height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: Colors.grey.shade400,
            shape: BoxShape.circle,
          ),
        )),
      ),
    );
  }
}