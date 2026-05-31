// ignore_for_file: curly_braces_in_flow_control_structures, use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';
import 'members_screen.dart';

class ChannelsScreen extends StatefulWidget {
  final String communityId;
  final String communityName;
  final String ownerId;

  const ChannelsScreen({
    super.key,
    required this.communityId,
    required this.communityName,
    required this.ownerId,
  });

  @override
  State<ChannelsScreen> createState() => _ChannelsScreenState();
}

class _ChannelsScreenState extends State<ChannelsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ─── KANAL OLUŞTUR ────────────────────────────────────────────────────────────
  void _createChannel() {
    final nameCtrl = TextEditingController();
    bool isReadOnly = false;
    String selectedEmoji = '💬';
    bool isCreating = false;

    final emojis = ['💬', '📢', '📚', '❓', '🎯', '📝', '🔔', '⭐'];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Yeni Kanal Oluştur',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Kanal İkonu',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: emojis.map((e) {
                  final bool sel = e == selectedEmoji;
                  return GestureDetector(
                    onTap: () => setS(() => selectedEmoji = e),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: sel
                            ? const Color(0xFFEEF2FF)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: sel
                              ? const Color(0xFF4F46E5)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(e, style: const TextStyle(fontSize: 20)),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Kanal Adı',
                  prefixIcon: const Icon(
                    Icons.tag,
                    color: Color(0xFF4F46E5),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF4F46E5),
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFFF8FAFC),
                ),
                child: SwitchListTile(
                  title: const Text(
                    'Sadece Duyuru',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Yalnızca kurucu mesaj atabilir',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: isReadOnly,
                  activeColor: Colors.orange,
                  onChanged: (v) => setS(() => isReadOnly = v),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isCreating ? null : () => Navigator.pop(ctx),
              child: const Text('İptal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: isCreating
                  ? null
                  : () async {
                      if (nameCtrl.text.trim().isEmpty) return;
                      setS(() => isCreating = true);
                      try {
                        await _firestore.collection('channels').add({
                          'communityId': widget.communityId,
                          'name': nameCtrl.text.trim(),
                          'emoji': selectedEmoji,
                          'isReadOnly': isReadOnly,
                          'createdBy': _auth.currentUser!.uid,
                          'createdAt': FieldValue.serverTimestamp(),
                          'unreadBy': [], // دعم الإشعارات
                        });
                        if (mounted) Navigator.pop(ctx);
                      } catch (e) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text('Hata: $e')),
                        );
                        setS(() => isCreating = false);
                      }
                    },
              child: isCreating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Oluştur',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── ÜYE DAVET ────────────────────────────────────────────────────────────────
  void _showInviteDialog() {
    final emailCtrl = TextEditingController();
    bool isInviting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.person_add_alt_1, color: Color(0xFF4F46E5)),
              SizedBox(width: 10),
              Text(
                'Üye Davet Et',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'E-posta adresi',
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: Color(0xFF4F46E5),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF4F46E5),
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade700,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Kullanıcı davet edildiğinde topluluk listesinde görünecek.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isInviting ? null : () => Navigator.pop(ctx),
              child: const Text('İptal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: isInviting
                  ? null
                  : () async {
                      final email = emailCtrl.text.trim().toLowerCase();
                      if (email.isEmpty || !email.contains('@')) return;
                      setS(() => isInviting = true);
                      try {
                        await _firestore
                            .collection('communities')
                            .doc(widget.communityId)
                            .update({
                              'allowedEmails': FieldValue.arrayUnion([email]),
                            });
                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Üye başarıyla davet edildi! ✅'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text('Hata: $e')),
                        );
                        setS(() => isInviting = false);
                      }
                    },
              child: isInviting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Davet Et',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── KANAL SİL ────────────────────────────────────────────────────────────────
  void _deleteChannel(String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Kanalı Sil', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          '#$name kanalı ve tüm mesajları silinecek. Emin misiniz?',
        ),
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
              Navigator.pop(ctx);
              await _firestore.collection('channels').doc(id).delete();
            },
            child: const Text(
              'Evet, Sil',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isOwner = _auth.currentUser?.uid == widget.ownerId;
    final String myUid = _auth.currentUser?.uid ?? '';

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
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEEF2FF), Color(0xFFC7D2FE)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  widget.communityName.isNotEmpty
                      ? widget.communityName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Color(0xFF4F46E5),
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.communityName,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1F2937),
                  fontSize: 18,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          if (isOwner) ...[
            IconButton(
              icon: const Icon(
                Icons.people_outline,
                color: Color(0xFF4F46E5),
              ),
              tooltip: 'Üyeler',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MembersScreen(
                    communityId: widget.communityId,
                    communityName: widget.communityName,
                    isOwner: isOwner,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.person_add_alt_1,
                color: Color(0xFF4F46E5),
              ),
              tooltip: 'Üye Davet Et',
              onPressed: _showInviteDialog,
            ),
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                icon: const Icon(Icons.add, color: Colors.white, size: 20),
                tooltip: 'Yeni Kanal',
                onPressed: _createChannel,
              ),
            ),
          ] else
            IconButton(
              icon: const Icon(
                Icons.people_outline,
                color: Color(0xFF4F46E5),
              ),
              tooltip: 'Üyeler',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MembersScreen(
                    communityId: widget.communityId,
                    communityName: widget.communityName,
                    isOwner: isOwner,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('channels')
            .where('communityId', isEqualTo: widget.communityId)
            .orderBy('createdAt')
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.hasError)
            return const Center(child: Text('Bir hata oluştu.'));
          if (snap.connectionState == ConnectionState.waiting)
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
            );

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.tag,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz kanal yok',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 16,
                    ),
                  ),
                  if (isOwner) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _createChannel,
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text(
                        'İlk Kanalı Oluştur',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }

          final announceChannels = docs.where(
            (d) => (d.data() as Map)['isReadOnly'] == true,
          ).toList();
          final normalChannels = docs.where(
            (d) => (d.data() as Map)['isReadOnly'] != true,
          ).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (announceChannels.isNotEmpty) ...[
                _sectionHeader('📢 DUYURU KANALLARI', Colors.orange),
                const SizedBox(height: 8),
                ...announceChannels.map(
                  (doc) => _channelCard(doc, isOwner, myUid),
                ),
                const SizedBox(height: 16),
              ],
              if (normalChannels.isNotEmpty) ...[
                _sectionHeader('💬 KANALLAR', const Color(0xFF4F46E5)),
                const SizedBox(height: 8),
                ...normalChannels.map((doc) => _channelCard(doc, isOwner, myUid)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color.withOpacity(0.8),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _channelCard(QueryDocumentSnapshot doc, bool isOwner, String myUid) {
    final data = doc.data() as Map<String, dynamic>;
    final String name = data['name'] ?? 'Kanal';
    final bool isReadOnly = data['isReadOnly'] ?? false;
    final String emoji = data['emoji'] ?? (isReadOnly ? '📢' : '💬');
    final bool isGenel = name.toLowerCase() == 'genel';

    // فحص ما إذا كانت القناة تحتوي على رسائل جديدة
    final List unreadBy = data['unreadBy'] ?? [];
    final bool hasUnread = unreadBy.contains(myUid);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: hasUnread ? const Color(0xFFEEF2FF) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: hasUnread ? const Color(0xFF4F46E5) : Colors.grey.shade100),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            // مسح الشارة بمجرد النقر على القناة
            if (hasUnread) {
              _firestore.collection('channels').doc(doc.id).update({
                'unreadBy': FieldValue.arrayRemove([myUid])
              });
            }
            
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  channelId: doc.id,
                  channelName: name,
                  isReadOnly: isReadOnly,
                  isOwner: isOwner,
                  ownerId: widget.ownerId,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Badge(
                  isLabelVisible: hasUnread,
                  smallSize: 10,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isReadOnly
                          ? Colors.orange.shade50
                          : const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontWeight: hasUnread ? FontWeight.w900 : FontWeight.bold,
                              fontSize: 15,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                          if (isReadOnly) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'DUYURU',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isReadOnly
                            ? 'Sadece kurucu yazabilir'
                            : 'Tüm üyeler yazabilir',
                        style: TextStyle(
                          color: hasUnread ? const Color(0xFF4F46E5) : Colors.grey.shade500,
                          fontSize: 12,
                          fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isOwner && !isGenel)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (v) {
                      if (v == 'delete') _deleteChannel(doc.id, name);
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Kanalı Sil',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey.shade300,
                    size: 16,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}