import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Follow a user
  Future<void> followUser(String currentUserID, String targetUserID) async {
    try {
      // Add targetUserID to current user's following list
      await _db.collection('users').doc(currentUserID).update({
        'following': FieldValue.arrayUnion([targetUserID])
      });

      // Add currentUserID to target user's followers list
      await _db.collection('users').doc(targetUserID).update({
        'followers': FieldValue.arrayUnion([currentUserID])
      });

      // Send notification to target user
      await sendFollowNotification(currentUserID, targetUserID);
    } catch (e) {
      print('Error following user: $e');
    }
  }

  // Send follow notification
  Future<void> sendFollowNotification(String currentUserID, String targetUserID) async {
    // Fetch the current user's name
    DocumentSnapshot userDoc = await _db.collection('users').doc(currentUserID).get();
    String username = userDoc['name'];

    // Create the notification message
    String message = '$username followed your account';

    // Store notification
    await _db.collection('notifications').add({
      'type': 'follow',
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'toUserID': targetUserID
    });
  }

  // Unfollow logic
  Future<void> unfollowUser(String currentUserID, String targetUserID) async {
    try {
      // Remove targetUserID from current user's following list
      await _db.collection('users').doc(currentUserID).update({
        'following': FieldValue.arrayRemove([targetUserID])
      });

      // Remove currentUserID from target user's followers list
      await _db.collection('users').doc(targetUserID).update({
        'followers': FieldValue.arrayRemove([currentUserID])
      });
    } catch (e) {
      print('Error unfollowing user: $e');
    }
  }
}
