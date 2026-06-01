// ignore_for_file: use_build_context_synchronously, deprecated_member_use, curly_braces_in_flow_control_structures, prefer_const_constructors, unused_field

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'channels_screen.dart';
import 'profile_screen.dart';
import 'dm_screen.dart';
import 'welcome_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _selectedTab = 0; // 0=Topluluklar, 1=DM, 2=Profil
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  // لحفظ عدد الرسائل غير المقروءة السابقة لمنع تكرار الإشعار المنبثق
  final Map<String, int> _previousUnreadCounts = {}; 
  final Map<String, bool> _notifiedChannels = {};

  @override
  void initState() {
    super.initState();
    _listenForNewMessages();
    _listenForChannelNotifications();
  }

  // ─── جلب الإشعارات المنبثقة (In-App Notification) ─────────────
  // ─── جلب الإشعارات المنبثقة للقنوات والمجتمعات ─────────────
  void _listenForChannelNotifications() {
    final user = _auth.currentUser;
    if (user == null) return;

    _firestore
        .collection('channels')
        .where('unreadBy', arrayContains: user.uid)
        .snapshots()
        .listen((snap) {
      for (var change in snap.docChanges) {
        // إذا تمت إضافتك لقائمة "غير المقروءة" (يعني هناك رسالة جديدة)
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          final channelId = change.doc.id;
          final channelName = data['name'] ?? 'Kanal';
          
          final bool wasNotified = _notifiedChannels[channelId] ?? false;
          
          // لمنع تكرار الإشعار لنفس القناة إذا لم تقرأها بعد
          if (!wasNotified) {
            _notifiedChannels[channelId] = true;
            
            // جلب آخر رسالة في هذه القناة لمعرفة اسم المرسل والمحتوى
            _firestore.collection('messages')
                .where('channelId', isEqualTo: channelId)
                .orderBy('createdAt', descending: true)
                .limit(1)
                .get()
                .then((msgSnap) {
              if (msgSnap.docs.isNotEmpty && mounted) {
                final msgData = msgSnap.docs.first.data();
                
                // إذا كنت أنت من أرسل الرسالة (للتأكد فقط)، لا تظهر إشعار
                if (msgData['senderId'] == user.uid) return;

                final sender = msgData['senderName'] ?? 'Biri';
                final text = (msgData['text']?.toString().isNotEmpty == true) 
                    ? msgData['text'] 
                    : 'Dosya/Fotoğraf gönderdi';
                
                // إظهار البانر من الأعلى (اسم القناة - اسم المرسل)
                _showTopBannerNotification('#$channelName - $sender', text);
              }
            });
          }
        } 
        // عندما تفتح القناة وتقرأ الرسالة، يتم إزالتك من القائمة
        else if (change.type == DocumentChangeType.removed) {
           _notifiedChannels.remove(change.doc.id);
        }
      }
    });
  }

  // ─── دالة إظهار الإشعار المنبثق من الأعلى ─────────────
  void _showTopBannerNotification(String title, String body) {
    if (!mounted) return;
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: -100.0, end: 0.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, value),
                child: child,
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
                ],
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.message, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(body, style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    // إخفاء الإشعار بعد 3 ثوانٍ
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) entry.remove();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─── YENİ TOPLULUK OLUŞTUR ──────────────────────────────────────────────────
  void _createCommunity() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    bool isCreating = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Yeni Topluluk Oluştur',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField(nameCtrl, 'Topluluk Adı', Icons.groups_outlined),
              const SizedBox(height: 12),
              _dialogField(
                descCtrl,
                'Açıklama (isteğe bağlı)',
                Icons.description_outlined,
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isCreating ? null : () => Navigator.pop(ctx),
              child: const Text(
                'İptal',
                style: TextStyle(color: Colors.grey),
              ),
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
                        final user = _auth.currentUser!;
                        final ref = await _firestore
                            .collection('communities')
                            .add({
                          'name': nameCtrl.text.trim(),
                          'description': descCtrl.text.trim(),
                          'ownerId': user.uid,
                          'members': [user.uid],
                          'allowedEmails': [
                            user.email!.toLowerCase(),
                          ],
                          'createdAt': FieldValue.serverTimestamp(),
                        });

                        // Varsayılan kanallar oluştur
                        for (final channel in [
                          {'name': 'Genel', 'isReadOnly': false, 'emoji': '💬'},
                          {'name': 'Duyurular', 'isReadOnly': true, 'emoji': '📢'},
                          {'name': 'Kaynaklar', 'isReadOnly': false, 'emoji': '📚'},
                        ]) {
                          await _firestore.collection('channels').add({
                            'communityId': ref.id,
                            'name': channel['name'],
                            'isReadOnly': channel['isReadOnly'],
                            'emoji': channel['emoji'],
                            'createdBy': user.uid,
                            'createdAt': FieldValue.serverTimestamp(),
                            // إعداد مبدئي للإشعارات
                            'unreadBy': [], 
                          });
                        }

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

  // ─── TOPLULUK SİL ────────────────────────────────────────────────────────────
  void _deleteCommunity(String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text(
              'Topluluğu Sil',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text('"$name" silinecek. Bu işlem geri alınamaz!'),
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
              await _firestore.collection('communities').doc(id).delete();
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

  // ─── BUILD ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) return const SizedBox();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildTopBar(user),
          Expanded(
            child: _selectedTab == 0
                ? _buildCommunitiesTab(user)
                : _selectedTab == 1
                ? _buildDMTab(user)
                : _buildActivityTab(user),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _selectedTab == 0
          ? FloatingActionButton.extended(
              onPressed: _createCommunity,
              backgroundColor: const Color(0xFF4F46E5),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Yeni Topluluk',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }

  // ─── ÜST BAR ─────────────────────────────────────────────────────────────────
  Widget _buildTopBar(User user) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Row(
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.center_focus_strong,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Odaksınıf',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              if (_selectedTab == 0)
                Expanded(
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) =>
                          setState(() => _searchQuery = v.toLowerCase()),
                      decoration: InputDecoration(
                        hintText: 'Topluluk ara...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF4F46E5),
                          size: 18,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                )
              else
                const Spacer(),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                ),
                child: FutureBuilder<DocumentSnapshot>(
                  future: _firestore
                      .collection('users')
                      .doc(user.uid)
                      .get(),
                  builder: (ctx, snap) {
                    final name = (snap.data?.data()
                            as Map<String, dynamic>?)?['fullName'] ??
                        user.email?[0].toUpperCase() ??
                        'U';
                    final initial =
                        name.toString().isNotEmpty ? name[0].toUpperCase() : 'U';
                    return Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── TOPLULUKLAR TAB ─────────────────────────────────────────────────────────
  Widget _buildCommunitiesTab(User user) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('communities')
          .where('allowedEmails', arrayContains: user.email)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting)
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
          );

        final all = snap.data?.docs ?? [];
        final filtered = all.where((d) {
          final n = (d.data() as Map)['name'].toString().toLowerCase();
          return n.contains(_searchQuery);
        }).toList();

        if (all.isEmpty) return _buildEmptyState();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            _buildHeroBanner(user, all.length),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text(
                  'Topluluklarım',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${filtered.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...filtered.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final isOwner = data['ownerId'] == user.uid;

              // ── إضافة المستخدم لقائمة الأعضاء تلقائياً لتعمل الإشعارات ──
              final List members = List.from(data['members'] ?? []);
              if (!members.contains(user.uid)) {
                doc.reference.update({
                  'members': FieldValue.arrayUnion([user.uid])
                });
              }
              // ───────────────────────────────────────────────────

              return _buildCommunityCard(doc.id, data, isOwner, user.uid);
            }),
          ],
        );
      },
    );
  }

  Widget _buildHeroBanner(User user, int count) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Merhaba! 👋',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                FutureBuilder<DocumentSnapshot>(
                  future: _firestore
                      .collection('users')
                      .doc(user.uid)
                      .get(),
                  builder: (ctx, snap) {
                    final name = (snap.data?.data()
                            as Map<String, dynamic>?)?['fullName'] ??
                        user.email?.split('@')[0] ??
                        '';
                    return Text(
                      name.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _statBadge('$count', 'Topluluk'),
                    const SizedBox(width: 10),
                    _statBadge('∞', 'Kanal'),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.groups_outlined,
              color: Colors.white,
              size: 36,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBadge(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityCard(
    String id,
    Map<String, dynamic> data,
    bool isOwner,
    String myUid,
  ) {
    final String initial = data['name'].toString().isNotEmpty
        ? data['name'].toString()[0].toUpperCase()
        : '?';

    // التحقق مما إذا كان هناك إشعارات (نقطة حمراء للمجتمعات)
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('channels')
          .where('communityId', isEqualTo: id)
          .where('unreadBy', arrayContains: myUid)
          .snapshots(),
      builder: (context, snapshot) {
        final bool hasUnread = snapshot.hasData && snapshot.data!.docs.isNotEmpty;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
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
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChannelsScreen(
                    communityId: id,
                    communityName: data['name'] ?? 'Topluluk',
                    ownerId: data['ownerId'] ?? '',
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Badge(
                      isLabelVisible: hasUnread,
                      smallSize: 12,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEEF2FF), Color(0xFFC7D2FE)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            initial,
                            style: const TextStyle(
                              color: Color(0xFF4F46E5),
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['name'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF1F2937),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if ((data['description'] ?? '').isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              data['description'],
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              if (isOwner)
                                _tag('Kurucu', Colors.green)
                              else
                                _tag('Üye', Colors.blue),
                              const SizedBox(width: 6),
                              _tag(
                                '${(data['allowedEmails'] as List?)?.length ?? 0} üye',
                                Colors.grey,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (isOwner)
                      GestureDetector(
                        onTap: () => _deleteCommunity(id, data['name']),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
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
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color.withOpacity(0.8),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.group_add_outlined,
              size: 64,
              color: Color(0xFF4F46E5),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Henüz topluluğun yok',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'İlk topluluğunu oluştur veya\nbir davet bekle',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createCommunity,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Topluluk Oluştur',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ─── DM TAB ───────────────────────────────────────────────────────────────────
  Widget _buildDMTab(User user) {
  return StreamBuilder<QuerySnapshot>(
    stream: _firestore
        .collection('dm_conversations')
        .where('participants', arrayContains: user.uid)
        .snapshots(),
    builder: (ctx, snap) {
      final docs = snap.data?.docs ?? [];

      final sorted = [...docs];
      sorted.sort((a, b) {
        final aT = (a.data() as Map)['lastMessageAt'] as Timestamp?;
        final bT = (b.data() as Map)['lastMessageAt'] as Timestamp?;
        if (aT == null && bT == null) return 0;
        if (aT == null) return -1;
        if (bT == null) return -1;
        return bT.compareTo(aT);
      });

      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Özel Mesajlar',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _startNewDM(user),
                  icon: const Icon(Icons.add, size: 18, color: Colors.white),
                  label: const Text(
                    'Yeni DM',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),

          if (sorted.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mail_outline,
                        size: 52,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Henüz özel mesajın yok',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '"Yeni DM" ile birine mesaj at',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                itemCount: sorted.length,
                itemBuilder: (ctx, i) {
                  final data = sorted[i].data() as Map<String, dynamic>;
                  final List parts = data['participants'] ?? [];
                  final String otherId =
                      parts.firstWhere((p) => p != user.uid, orElse: () => '');
                  final String lastMsg = data['lastMessage'] ?? '';
                  final int unreadCount = data['unreadCount_${user.uid}'] ?? 0;
                  final bool hasUnread = unreadCount > 0;

                  return FutureBuilder<DocumentSnapshot>(
                    future: _firestore.collection('users').doc(otherId).get(),
                    builder: (ctx, userSnap) {
                      final uData =
                          userSnap.data?.data() as Map<String, dynamic>?;
                      final String otherName =
                          uData?['fullName'] ?? uData?['name'] ?? 'Kullanıcı';
                      final String otherEmail = uData?['email'] ?? '';
                      final String initial = otherName.isNotEmpty
                          ? otherName[0].toUpperCase()
                          : '?';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: hasUnread
                              ? const Color(0xFFF5F3FF)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: hasUnread
                                ? const Color(0xFFC7D2FE)
                                : Colors.grey.shade100,
                          ),
                        ),
                        child: ListTile(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DMScreen(
                                conversationId: sorted[i].id,
                                otherUserId: otherId,
                                otherUserName: otherName,
                                otherUserEmail: otherEmail,
                              ),
                            ),
                          ),
                          leading: Badge(
                            isLabelVisible: hasUnread,
                            label: Text(unreadCount.toString()),
                            child: CircleAvatar(
                              backgroundColor: const Color(0xFF4F46E5),
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            otherName,
                            style: TextStyle(
                              fontWeight: hasUnread
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                          subtitle: Text(
                            lastMsg.isEmpty ? 'Mesaj yok' : lastMsg,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: hasUnread
                                  ? const Color(0xFF4F46E5)
                                  : Colors.grey,
                              fontWeight: hasUnread
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
        ],
      );
    },
  );
}

  // ─── YENİ DM BAŞLAT ──────────────────────────────────────────────────────────
  void _startNewDM(User currentUser) {
    final emailCtrl = TextEditingController();
    bool isSearching = false;
    Map<String, dynamic>? foundUser;
    String? foundUserId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Yeni Özel Mesaj',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: emailCtrl,
                      decoration: InputDecoration(
                        hintText: 'E-posta ile ara...',
                        prefixIcon: const Icon(
                          Icons.search,
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
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(12),
                    ),
                    onPressed: isSearching
                        ? null
                        : () async {
                            final q = emailCtrl.text.trim().toLowerCase();
                            if (q.isEmpty) return;
                            setS(() {
                              isSearching = true;
                              foundUser = null;
                            });
                            final snap = await _firestore
                                .collection('users')
                                .where('email', isEqualTo: q)
                                .limit(1)
                                .get();
                            if (snap.docs.isNotEmpty &&
                                snap.docs.first.id != currentUser.uid) {
                              setS(() {
                                foundUser = snap.docs.first.data();
                                foundUserId = snap.docs.first.id;
                              });
                            } else {
                              setS(() => foundUser = null);
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text('Kullanıcı bulunamadı.'),
                                ),
                              );
                            }
                            setS(() => isSearching = false);
                          },
                    child: isSearching
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.search, color: Colors.white),
                  ),
                ],
              ),
              if (foundUser != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFF4F46E5),
                        child: Text(
                          (foundUser!['fullName'] ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              foundUser!['fullName'] ?? 'İsimsiz',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              foundUser!['email'] ?? '',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal', style: TextStyle(color: Colors.grey)),
            ),
            if (foundUser != null)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _openOrCreateDM(currentUser, foundUserId!, foundUser!);
                },
                child: const Text(
                  'Mesaj Gönder',
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

  Future<void> _openOrCreateDM(
    User currentUser,
    String otherUserId,
    Map<String, dynamic> otherUserData,
  ) async {
    try {
      String? convId;
      final existing = await _firestore
          .collection('dm_conversations')
          .where('participants', arrayContains: currentUser.uid)
          .get();

      for (final doc in existing.docs) {
        final List parts = (doc.data()['participants'] as List?) ?? [];
        if (parts.contains(otherUserId)) {
          convId = doc.id;
          break;
        }
      }

      if (convId == null) {
        final ref = await _firestore
            .collection('dm_conversations')
            .add({
          'participants': [currentUser.uid, otherUserId],
          'participantEmails': [
            currentUser.email?.toLowerCase() ?? '',
            (otherUserData['email'] ?? '').toString().toLowerCase(),
          ],
          'lastMessage': '',
          'lastMessageAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'unreadCount_${currentUser.uid}': 0,
          'unreadCount_$otherUserId': 0,
        });
        convId = ref.id;
      }

      if (mounted) {
        final String otherName =
            otherUserData['fullName'] ??
            otherUserData['name'] ??
            otherUserData['adSoyad'] ??
            'Kullanıcı';
        final String otherEmail =
            otherUserData['email']?.toString() ?? '';

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DMScreen(
              conversationId: convId!,
              otherUserId: otherUserId,
              otherUserName: otherName,
              otherUserEmail: otherEmail,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('DM açılamadı: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ─── AKTİVİTE TAB ───────────────────────────────────────
  Widget _buildActivityTab(User user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hızlı Erişim',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 14),
          _quickCard(
            icon: Icons.person_outline,
            color: const Color(0xFF4F46E5),
            title: 'Profilimi Düzenle',
            subtitle: 'Ad, soyad ve profil ayarları',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
          _quickCard(
            icon: Icons.logout,
            color: Colors.red,
            title: 'Çıkış Yap',
            subtitle: 'Hesabından güvenli çıkış yap',
            onTap: () async {
              await _auth.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                  (r) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _quickCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey.shade300,
          size: 16,
        ),
      ),
    );
  }

  // ─── ALT NAV ─────────────────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    final uid = _auth.currentUser?.uid ?? '';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.groups_outlined, Icons.groups, 'Topluluklar'),
              // StreamBuilder لحساب عدد الرسائل غير المقروءة ووضعه في شريط التنقل
              StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('dm_conversations')
                    .where('participants', arrayContains: uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  int totalUnread = 0;
                  if (snapshot.hasData) {
                    for (var doc in snapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      totalUnread += (data['unreadCount_$uid'] as int?) ?? 0;
                    }
                  }
                  return _navItem(1, Icons.mail_outline, Icons.mail, 'Mesajlar', badgeCount: totalUnread);
                }
              ),
              _navItem(2, Icons.more_horiz, Icons.more_horiz, 'Daha Fazla'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label, {
    int badgeCount = 0,
  }) {
    final bool isActive = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Badge(
            isLabelVisible: badgeCount > 0,
            label: Text('$badgeCount'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFFEEF2FF)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isActive ? activeIcon : icon,
                color: isActive ? const Color(0xFF4F46E5) : Colors.grey,
                size: 24,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isActive ? const Color(0xFF4F46E5) : Colors.grey,
              fontWeight:
                  isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // ─── YARDIMCILAR ─────────────────────────────────────────────────────────────
  Widget _dialogField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF4F46E5)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
        ),
      ),
    );
  }
  
  void _listenForNewMessages() {}
}