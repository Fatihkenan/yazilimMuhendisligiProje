// ignore_for_file: unused_import

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/community_model.dart';
import '../models/channel_model.dart';
import '../models/message_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- 1. TOPLULUK OLUŞTURMA ---
  Future<void> createCommunity({
    required String name,
    required String description,
    required String ownerId,
    required String ownerEmail,
  }) async {
    final communityRef = await _firestore.collection('communities').add({
      'name': name,
      'description': description,
      'ownerId': ownerId,
      'members': [ownerId],
      'allowedEmails': [ownerEmail.toLowerCase()],
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Topluluk kurulurken varsayılan 'Genel' kanalını da otomatik açıyoruz
    await createChannel(
      communityId: communityRef.id,
      name: 'Genel',
      creatorId: ownerId,
    );
  }

  // --- 2. KANAL OLUŞTURMA ---
  Future<void> createChannel({
    required String communityId,
    required String name,
    required String creatorId,
  }) async {
    await _firestore.collection('channels').add({
      'communityId': communityId,
      'name': name,
      'createdBy': creatorId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // --- 3. E-POSTA İLE ÜYE DAVET ETME ---
  Future<void> inviteMember({
    required String communityId,
    required String email,
  }) async {
    await _firestore.collection('communities').doc(communityId).update({
      'allowedEmails': FieldValue.arrayUnion([email.trim().toLowerCase()]),
    });
  }

  // --- 4. KANALA MESAJ GÖNDERME ---
  Future<void> sendMessage({
    required String channelId,
    required String senderId,
    required String senderName,
    required String content,
    String? fileUrl,
  }) async {
    await _firestore.collection('messages').add({
      'channelId': channelId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'fileUrl': fileUrl, // Eğer PDF/Resim varsa buraya linki gelecek
      'readBy': [], // Sprint 5 Okundu bilgisi için hazır liste!
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
