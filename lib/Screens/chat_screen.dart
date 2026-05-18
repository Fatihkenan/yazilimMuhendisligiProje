import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart'; 

class ChatScreen extends StatefulWidget {
  final String channelId;
  final String channelName;
  final bool isReadOnly;
  final bool isOwner;

  const ChatScreen({
    super.key,
    required this.channelId,
    required this.channelName,
    required this.isReadOnly,
    required this.isOwner,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker(); 

  void _pickAndUploadImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70, 
    );

    if (image == null) return;

    final User? user = _auth.currentUser;
    if (user == null) return;

    try {
      String simulatedImageUrl = image.path; 

      await _firestore.collection('messages').add({
        'channelId': widget.channelId,
        'text': '', 
        'imageUrl': simulatedImageUrl, 
        'senderId': user.uid,
        'senderEmail': user.email,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fotoğraf gönderilemedi: $e')),
        );
      }
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final User? user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('messages').add({
        'channelId': widget.channelId,
        'text': _messageController.text.trim(),
        'imageUrl': null, 
        'senderId': user.uid,
        'senderEmail': user.email,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canType = !widget.isReadOnly || widget.isOwner;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4F46E5),
        title: Text(
          '# ${widget.channelName}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
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
                if (snapshot.hasError) {
                  return Center(child: Text('Hata: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Bu kanalda henüz mesaj yok.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final bool isMe = data['senderId'] == _auth.currentUser?.uid;
                    final String? imageUrl = data['imageUrl'];
                    final String text = data['text'] ?? '';

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFF4F46E5) : Colors.white,
                          borderRadius: BorderRadius.circular(16).copyWith(
                            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(16),
                            bottomLeft: !isMe ? const Radius.circular(0) : const Radius.circular(16),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min, 
                          children: [
                            if (!isMe)
                              Text(
                                data['senderEmail'] ?? '',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            if (!isMe) const SizedBox(height: 4),
                            
                            
                            if (imageUrl != null && imageUrl.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: imageUrl.startsWith('http')
                                      ? Image.network(imageUrl, width: 200, height: 150, fit: BoxFit.cover)
                                      : Image.file(File(imageUrl), width: 200, height: 150, fit: BoxFit.cover),
                                ),
                              )
                            else if (text.isNotEmpty)
                              Text(
                                text,
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black87,
                                  fontSize: 15,
                                ),
                              ),
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
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: Color(0xFF4F46E5), size: 28),
                      onPressed: _pickAndUploadImage,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Mesajınızı yazın...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF3F4F6),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF4F46E5),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: Colors.grey.shade200,
              child: const SafeArea(
                child: Text(
                  'Sadece yöneticiler mesaj gönderebilir.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}