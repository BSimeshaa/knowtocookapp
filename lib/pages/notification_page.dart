import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:knowtocook/pages/home_page.dart';
import 'package:knowtocook/pages/post_creation.dart';
import 'package:knowtocook/pages/search_page.dart';
import 'package:knowtocook/pages/user_profile.dart';

class NotificationsPage extends StatefulWidget {
  final String userId;
  final String currentUserId;
  final String targetUserId;

  const NotificationsPage({Key? key, required this.userId, required this.currentUserId, required this.targetUserId}) : super(key: key);

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {

  int _selectedIndex = 3;

  final List<Widget> _pages = [

    Center(child: Text("Home Page")),
    Center(child: Text("Search Page")),
    Center(child: Text("Post Page")),
    Center(child: Text("Notification Page")),
    Center(child: Text("Profile Page"),)
  ];

  //_onIconClicked method is used to handle the navigation of the BottomNavigationBar
  void _onIconClicked(int index) async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (index == 0 && currentUser != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(userId: currentUser.uid),
        ),
      );
    } else if (index == 2 && currentUser != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecipeCreationPage(userId: currentUser.uid),
        ),
      );
    } else if (index == 4 && currentUser != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserProfilePage(currentUserId: currentUser.uid,userId: currentUser.uid, targetUserId:''),
        ),
      );
    }else if (index == 1 && currentUser != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchPage(userId: currentUser.uid),
        ),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _toggleFollow(String targetUserId) async {
    String currentUserId = _auth.currentUser!.uid;
    DocumentReference followingRef = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('following')
        .doc(targetUserId);
    DocumentReference followerRef = _firestore
        .collection('users')
        .doc(targetUserId)
        .collection('followers')
        .doc(currentUserId);

    DocumentSnapshot followingSnapshot = await followingRef.get();

    if (followingSnapshot.exists) {
      await followingRef.delete();
      await followerRef.delete();

      await _firestore.collection('users').doc(currentUserId).update({
        'followingCount': FieldValue.increment(-1)
      });
      await _firestore.collection('users').doc(targetUserId).update({
        'followerCount': FieldValue.increment(-1)
      });
    } else {
      await followingRef.set({'timestamp': FieldValue.serverTimestamp()});
      await followerRef.set({'timestamp': FieldValue.serverTimestamp()});

      await _firestore.collection('users').doc(currentUserId).update({
        'followingCount': FieldValue.increment(1)
      });
      await _firestore.collection('users').doc(targetUserId).update({
        'followerCount': FieldValue.increment(1)
      });

      await _firestore.collection('users').doc(targetUserId).collection('notifications').add({
        'type': 'follow',
        'senderId': currentUserId,
        'timestamp': FieldValue.serverTimestamp()
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String currentUserId = _auth.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: Text('Notifications')),
      body: StreamBuilder(
        stream: _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          var notifications = snapshot.data!.docs;
          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              var notification = notifications[index];
              String senderId = notification['senderId'];
              String type = notification['type'];

              return FutureBuilder(
                future: _firestore.collection('users').doc(senderId).get(),
                builder: (context, AsyncSnapshot<DocumentSnapshot> userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return ListTile(title: Text('Loading...'));
                  }
                  var userData = userSnapshot.data!;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(userData['profileImage']),
                    ),
                    title: Text(userData['username']),
                    subtitle: Text(type == 'follow' ? 'started following you' : ''),
                    trailing: StreamBuilder(
                      stream: _firestore
                          .collection('users')
                          .doc(currentUserId)
                          .collection('following')
                          .doc(senderId)
                          .snapshots(),
                      builder: (context, AsyncSnapshot<DocumentSnapshot> followSnapshot) {
                        bool isFollowing = followSnapshot.hasData && followSnapshot.data!.exists;
                        return ElevatedButton(
                          onPressed: () => _toggleFollow(senderId),
                          child: Text(isFollowing ? 'Following' : 'Follow'),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),

// Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        currentIndex: 4,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: "Post"),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: "Notification"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );

  }
}

