import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:knowtocook/pages/user_profile.dart';

class AdminDashboardPage extends StatefulWidget {
  @override
  _AdminDashboardPageState createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Method to delete a post
  Future<void> _deletePost(String postId) async {
    try {
      await _firestore.collection('recipes').doc(postId).delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Post deleted successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // Method to delete a user profile
  Future<void> _deleteUser(String userId) async {
    try {
      // Delete user posts first
      QuerySnapshot postsSnapshot = await _firestore.collection('recipes').where('userID', isEqualTo: userId).get();
      for (var post in postsSnapshot.docs) {
        await _deletePost(post.id);  // Delete the post
      }

      // Now delete the user from 'users' collection
      await _firestore.collection('users').doc(userId).delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User deleted successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // Method to fetch and display users with their posts
  Widget _buildUserList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No users found.'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var user = snapshot.data!.docs[index];
            String userId = user.id;
            String userName = user['name'] ?? 'Unknown User'; // Default to 'Unknown User' if name is missing

            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        // Navigate to the user's profile page when their name is clicked
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserProfilePage(
                              userId: userId,
                              currentUserId: FirebaseAuth.instance.currentUser!.uid,
                              targetUserId: userId,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        userName, // Display the user's name
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text("User ID: $userId"),
                    SizedBox(height: 8),
                    // Show posts for this user
                    FutureBuilder<QuerySnapshot>(
                      future: _firestore.collection('recipes').where('userID', isEqualTo: userId).get(),
                      builder: (context, postSnapshot) {
                        if (postSnapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        if (postSnapshot.hasError) {
                          return Center(child: Text('Error: ${postSnapshot.error}'));
                        }

                        if (!postSnapshot.hasData || postSnapshot.data!.docs.isEmpty) {
                          return Center(child: Text('No posts found.'));
                        }

                        return Column(
                          children: postSnapshot.data!.docs.map((post) {
                            return ListTile(
                              title: Text(post['foodName'] ?? 'Untitled'),
                              subtitle: Text(post['description'] ?? 'No description'),
                              leading: Image.network(post['imageUrl'] ?? '', width: 50, height: 50),
                              trailing: IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deletePost(post.id),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    // Button to delete user
                    ElevatedButton(
                      onPressed: () => _deleteUser(userId),
                      child: Text("Delete User"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        backgroundColor: Colors.green,
      ),
      body: _buildUserList(),
    );
  }
}
