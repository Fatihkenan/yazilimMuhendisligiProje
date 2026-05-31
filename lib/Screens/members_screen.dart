// ignore_for_file: use_build_context_synchronously, deprecated_member_use, curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MembersScreen extends StatelessWidget {
  final String communityId;
  final String communityName;
  final bool isOwner;

  const MembersScreen({
    super.key,
    required this.communityId,
    required this.communityName,
    required this.isOwner,
  });

  @override
  Widget build(BuildContext context) {
    final currentEmail =
        FirebaseAuth.instance.currentUser?.email?.toLowerCase() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 1,
        shadowColor: Colors.black12,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
        title: const Text(
          'Üyeler',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('communities')
            .doc(communityId)
            .snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData)
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
            );

          final data = snap.data!.data() as Map<String, dynamic>?;
          final List<dynamic> emails = data?['allowedEmails'] ?? [];
          final String ownerId = data?['ownerId'] ?? '';

          return Column(
            children: [
              // Özet
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.people, color: Colors.white, size: 32),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${emails.length} Üye',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          communityName,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: emails.length,
                  itemBuilder: (ctx, i) {
                    final String email = emails[i].toString().toLowerCase();
                    final bool isMe = email == currentEmail;
                    final bool isCommunityOwner =
                        _getUidFromEmail(ownerId, email);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isMe
                              ? Colors.green.shade100
                              : const Color(0xFFEEF2FF),
                          child: Text(
                            email[0].toUpperCase(),
                            style: TextStyle(
                              color: isMe
                                  ? Colors.green
                                  : const Color(0xFF4F46E5),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          email,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          isMe
                              ? 'Sen'
                              : isCommunityOwner
                              ? 'Kurucu'
                              : 'Üye',
                          style: TextStyle(
                            color: isMe
                                ? Colors.green
                                : isCommunityOwner
                                ? Colors.orange
                                : Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: isOwner && !isMe
                            ? IconButton(
                                icon: const Icon(
                                  Icons.person_remove_outlined,
                                  color: Colors.red,
                                ),
                                tooltip: 'Çıkar',
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      title: const Text('Üyeyi Çıkar'),
                                      content: Text(
                                        '$email kullanıcısı topluluktan çıkarılacak.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text('İptal'),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          child: const Text(
                                            'Çıkar',
                                            style: TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await FirebaseFirestore.instance
                                        .collection('communities')
                                        .doc(communityId)
                                        .update({
                                          'allowedEmails':
                                              FieldValue.arrayRemove([email]),
                                        });
                                  }
                                },
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _getUidFromEmail(String ownerId, String email) => false;
}