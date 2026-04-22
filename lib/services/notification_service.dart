import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String get _currentUserId => _auth.currentUser?.uid ?? '';

  static Stream<int> totalUnreadStream() {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: _currentUserId)
        .snapshots()
        .map((snapshot) {
      int total = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final unread = data['unreadCount_$_currentUserId'];
        if (unread != null && unread is int) {
          total += unread;
        }
      }
      return total;
    });
  }

  static Stream<int> unreadAnnouncementsStream() {
    return _firestore
        .collection('messages')
        .where('readBy', whereNotIn: [
          [_currentUserId]
        ])
        .snapshots()
        .map((s) => s.docs.length);
  }

  static Future<void> markAllChatsAsRead() async {
    final chats = await _firestore
        .collection('chats')
        .where('participants', arrayContains: _currentUserId)
        .get();

    for (final doc in chats.docs) {
      await doc.reference
          .set({'unreadCount_$_currentUserId': 0}, SetOptions(merge: true));
    }
  }
}