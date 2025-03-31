import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:knowtocook/pages/home_page.dart'; // Import HomePage

class NotificationsPage extends StatefulWidget {
  final String currentUserID;

  const NotificationsPage({
    Key? key,
    required this.currentUserID,
  }) : super(key: key);

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Method to build each notification card
  Widget _buildNotificationCard(DocumentSnapshot notification, String notificationId) {
    String message = notification['message'] ?? 'No message';
    String triggeredBy = notification['triggeredBy'] ?? 'Unknown';  // Using triggeredBy here
    Timestamp timestamp = notification['timestamp'];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 5,
      child: ListTile(
        leading: CircleAvatar(
          radius: 20,
          backgroundImage: NetworkImage('https://example.com/user-avatar.jpg'), // Replace with actual avatar URL
        ),
        title: Text("$triggeredBy $message"), // Display who triggered the notification
        subtitle: Text('At ${timestamp.toDate()}'),
        trailing: IconButton(
          icon: Icon(Icons.delete, color: Colors.red),
          onPressed: () {
            _deleteNotification(notificationId);
          },
        ),
      ),
    );
  }

  // Method to delete a notification from Firestore
  Future<void> _deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Notification deleted')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

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
                  MaterialPageRoute(builder: (context) => HomePage(userId: widget.currentUserID)), // Navigate to HomePage
                );
              },
            ),
            Text("Notifications", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('notifications')
            .where('userId', isEqualTo: widget.currentUserID) // Fetch notifications for the current user
            .orderBy('timestamp', descending: true) // Order notifications by timestamp
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No notifications"));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var notification = snapshot.data!.docs[index];
              String notificationId = notification.id; // Access the document ID

              return _buildNotificationCard(notification, notificationId); // Display each notification card
            },
          );
        },
      ),
    );
  }
}
