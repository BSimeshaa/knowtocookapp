import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:knowtocook/pages/home_page.dart'; // Import HomePage

class NotificationsPage extends StatelessWidget {
  final String currentUserID;

  const NotificationsPage({Key? key, required this.currentUserID, required String targetUserId, required String userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Remove the default back button
        title: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back), // Custom back arrow
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => HomePage(userId: currentUserID)), // Navigate to HomePage
                );
              },
            ),
            Text("Notifications", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('toUserID', isEqualTo: currentUserID)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (ctx, index) {
              return ListTile(
                title: Text(notifications[index]['message']),
                subtitle: Text(notifications[index]['timestamp'].toDate().toString()),
              );
            },
          );
        },
      ),
    );
  }
}
