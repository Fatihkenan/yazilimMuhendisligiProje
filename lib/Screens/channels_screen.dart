import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';

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

  void _showInviteMemberDialog() {
    final emailController = TextEditingController();
    bool isInviting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Üye Davet Et',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Öğrencinin E-posta Adresi',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isInviting ? null : () => Navigator.pop(context),
                  child: const Text(
                    'İptal',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                  ),
                  onPressed: isInviting
                      ? null
                      : () async {
                          if (emailController.text.trim().isEmpty ||
                              !emailController.text.contains('@'))
                            return;
                          setState(() => isInviting = true);
                          try {
                            await _firestore
                                .collection('communities')
                                .doc(widget.communityId)
                                .update({
                                  'allowedEmails': FieldValue.arrayUnion([
                                    emailController.text.trim().toLowerCase(),
                                  ]),
                                });
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Üye başarıyla davet edildi!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text('Hata: $e')));
                            setState(() => isInviting = false);
                          }
                        },
                  child: isInviting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Davet Et',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCreateChannelDialog() {
    final nameController = TextEditingController();
    bool isCreating = false;
    bool isReadOnly = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Yeni Kanal Oluştur',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Kanal Adı',
                      prefixIcon: Icon(Icons.tag),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SwitchListTile(
                      title: const Text(
                        "Sadece Duyuru",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: const Text(
                        "Sadece yöneticiler mesaj gönderebilir.",
                        style: TextStyle(fontSize: 12),
                      ),
                      value: isReadOnly,
                      activeColor: const Color(0xFF4F46E5),
                      onChanged: (val) {
                        setState(() {
                          isReadOnly = val;
                        });
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isCreating ? null : () => Navigator.pop(context),
                  child: const Text(
                    'İptal',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                  ),
                  onPressed: isCreating
                      ? null
                      : () async {
                          if (nameController.text.trim().isEmpty) return;
                          setState(() => isCreating = true);
                          try {
                            await _firestore.collection('channels').add({
                              'communityId': widget.communityId,
                              'name': nameController.text.trim(),
                              'createdBy': _auth.currentUser!.uid,
                              'isReadOnly': isReadOnly,
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                            if (mounted) Navigator.pop(context);
                          } catch (e) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text('Hata: $e')));
                            setState(() => isCreating = false);
                          }
                        },
                  child: isCreating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Oluştur',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditChannelDialog(
    String channelId,
    String currentName,
    bool currentReadOnly,
  ) {
    bool isUpdating = false;
    bool newReadOnlyState = currentReadOnly;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                '#$currentName - Ayarlar',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SwitchListTile(
                      title: const Text(
                        "Sadece Duyuru",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: const Text(
                        "Sadece yöneticiler mesaj gönderebilir.",
                        style: TextStyle(fontSize: 12),
                      ),
                      value: newReadOnlyState,
                      activeColor: const Color(0xFF4F46E5),
                      onChanged: (val) {
                        setState(() {
                          newReadOnlyState = val;
                        });
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isUpdating ? null : () => Navigator.pop(context),
                  child: const Text(
                    'İptal',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                  ),
                  onPressed: isUpdating
                      ? null
                      : () async {
                          setState(() => isUpdating = true);
                          try {
                            await _firestore
                                .collection('channels')
                                .doc(channelId)
                                .update({'isReadOnly': newReadOnlyState});
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Kanal ayarları güncellendi.'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text('Hata: $e')));
                            setState(() => isUpdating = false);
                          }
                        },
                  child: isUpdating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Kaydet',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteChannel(String channelId, String channelName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Kanalı Sil',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        content: Text(
          '#$channelName kanalını silmek istediğinize emin misiniz?\n\nBu işlem geri alınamaz!',
        ),
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
                await _firestore.collection('channels').doc(channelId).delete();
                if (mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kanal silindi.'),
                      backgroundColor: Colors.red,
                    ),
                  );
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Hata: $e')));
              }
            },
            child: const Text(
              'Evet, Sil',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isOwner = _auth.currentUser?.uid == widget.ownerId;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF4F46E5),
        title: Text(
          widget.communityName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.person_add),
              tooltip: 'Üye Davet Et',
              onPressed: _showInviteMemberDialog,
            ),
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Yeni Kanal Ekle',
              onPressed: _showCreateChannelDialog,
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('channels')
            .where('communityId', isEqualTo: widget.communityId)
            .orderBy('createdAt')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return Center(child: Text('Bir hata oluştu: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
            );

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty)
            return const Center(
              child: Text(
                'Bu toplulukta henüz kanal yok.',
                style: TextStyle(color: Colors.grey),
              ),
            );

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final String channelName = data['name'] ?? 'İsimsiz Kanal';
              final bool isReadOnly = data['isReadOnly'] ?? false;

              final bool canManage =
                  isOwner && channelName.toLowerCase() != 'genel';

              return Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Icon(
                    isReadOnly ? Icons.campaign : Icons.tag,
                    color: isReadOnly ? Colors.orange : const Color(0xFF4F46E5),
                  ),
                  title: Row(
                    children: [
                      Text(
                        channelName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      if (isReadOnly)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Duyuru',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  trailing: canManage
                      ? PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Colors.grey),
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showEditChannelDialog(
                                docs[index].id,
                                channelName,
                                isReadOnly,
                              );
                            } else if (value == 'delete') {
                              _confirmDeleteChannel(
                                docs[index].id,
                                channelName,
                              );
                            }
                          },
                          itemBuilder: (BuildContext context) =>
                              <PopupMenuEntry<String>>[
                                const PopupMenuItem<String>(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.settings,
                                        size: 20,
                                        color: Colors.black87,
                                      ),
                                      SizedBox(width: 10),
                                      Text('Kanal Ayarları'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete_outline,
                                        size: 20,
                                        color: Colors.red,
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        'Kanalı Sil',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                        )
                      : const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          channelId: docs[index].id,
                          channelName: channelName,
                          isReadOnly: isReadOnly,
                          isOwner:
                              isOwner, // DÜZELTME: KIZARMAYI ÖNLEMEK İÇİN EKLENDİ
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
