import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FollowButton extends StatefulWidget {
  final String currentUserId;
  final String targetUserId;

  const FollowButton({
    required this.currentUserId,
    required this.targetUserId,
    Key? key,
  }) : super(key: key);

  @override
  _FollowButtonState createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  bool isFollowing = false;

  @override
  void initState() {
    super.initState();
    checkIfFollowing();
  }

  void checkIfFollowing() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('followers')
        .doc(widget.targetUserId)
        .collection('userFollowers')
        .doc(widget.currentUserId)
        .get();

    if (doc.exists) {
      setState(() {
        isFollowing = true;
      });
    }
  }

  void sendFollowRequest() async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(widget.targetUserId)
        .collection('userNotifications')
        .add({
      'type': 'follow_request',
      'fromUserId': widget.currentUserId,
      'timestamp': Timestamp.now(),
      'status': 'pending',
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Follow request sent!")),
    );
  }

  void acceptFollowRequest(String notificationId) async {
    await FirebaseFirestore.instance
        .collection('followers')
        .doc(widget.targetUserId)
        .collection('userFollowers')
        .doc(widget.currentUserId)
        .set({});

    await FirebaseFirestore.instance
        .collection('following')
        .doc(widget.currentUserId)
        .collection('userFollowing')
        .doc(widget.targetUserId)
        .set({});

    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(widget.targetUserId)
        .collection('userNotifications')
        .doc(notificationId)
        .update({'status': 'accepted'});

    setState(() {
      isFollowing = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isFollowing ? null : sendFollowRequest,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      child: Text(isFollowing ? "Following" : "Follow"),
    );
  }
}
