import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:knowtocook/pages/notification_page.dart';
import 'package:knowtocook/pages/post_creation.dart';
import 'package:knowtocook/pages/search_page.dart';
import 'package:knowtocook/pages/user_profile.dart';

class HomePage extends StatefulWidget {
  final String userId;

  const HomePage({super.key, required this.userId});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // List of pages to navigate to
  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    // Initialize the pages list with the corresponding pages
    _pages.addAll([
      _buildHomePage(),
      SearchPage(), // Search page
      RecipeCreationPage(userId: widget.userId), // Post page
      NotificationsPage(
        userId: widget.userId,
        targetUserId: widget.userId,
        currentUserID: widget.userId,
      ), // Notifications page
      UserProfilePage(
        userId: widget.userId,
        currentUserId: widget.userId,
        targetUserId: widget.userId,
      ), // Profile page
    ]);
  }

  Widget _buildHomePage() {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Remove back arrow
        title: Row(
          children: [
            Text("KnowToCook 🧑‍🍳",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(height: 16),
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('recipes') // Fetch posts collection
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text("No recipes available"));
                  }
                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var recipe = snapshot.data!.docs[index];
                      return RecipeCard(recipe: recipe);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Update selected index when an icon is clicked
  void _onIconClicked(int index) {
    setState(() {
      _selectedIndex = index; // Update the selected index
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],  // Display the selected page based on _selectedIndex
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.green,  // Color for selected item
        unselectedItemColor: Colors.grey,  // Color for unselected items
        currentIndex: _selectedIndex,  // Track the current selected index
        onTap: _onIconClicked,  // Handle icon tap to update index
        type: BottomNavigationBarType.fixed,  // Ensure all items are displayed
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),  // Home tab
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),  // Search tab
          BottomNavigationBarItem(icon: Icon(Icons.add), label: "Post"),  // Post tab
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: "Notification"),  // Notification tab
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),  // Profile tab
        ],
      ),
    );
  }
}

class RecipeCard extends StatefulWidget {
  final QueryDocumentSnapshot recipe;

  const RecipeCard({required this.recipe});

  @override
  _RecipeCardState createState() => _RecipeCardState();
}

class _RecipeCardState extends State<RecipeCard> {
  bool _isExpanded = false;
  bool _isLiked = false;
  late int _likesCount;

  @override
  void initState() {
    super.initState();
    var data = widget.recipe.data() as Map<String, dynamic>;
    _likesCount = data['likes'].length; // Set initial like count
    _isLiked = data['likes'].contains(FirebaseAuth.instance.currentUser!.uid); // Check if the current user has liked this post
  }

  Future<void> _toggleLike() async {
    var data = widget.recipe.data() as Map<String, dynamic>;
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    if (_isLiked) {
      // Un-like the post
      await FirebaseFirestore.instance.collection('recipes').doc(widget.recipe.id).update({
        'likes': FieldValue.arrayRemove([currentUserId]),
      });
      setState(() {
        _likesCount--;
        _isLiked = false;
      });
    } else {
      // Like the post
      await FirebaseFirestore.instance.collection('recipes').doc(widget.recipe.id).update({
        'likes': FieldValue.arrayUnion([currentUserId]),
      });
      setState(() {
        _likesCount++;
        _isLiked = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var data = widget.recipe.data() as Map<String, dynamic>;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(
              data['imageUrl'] ?? '',
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 200,
                color: Colors.grey[300],
                child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['foodName'] ?? 'Unknown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text(data['description'] ?? '', maxLines: _isExpanded ? null : 2, overflow: TextOverflow.ellipsis),
                SizedBox(height: 8),
                Text("⏳ ${data['cookingDuration']} | 🍽 Ingredients: ${data['ingredients'].length}"),
                if (_isExpanded) ...[
                  SizedBox(height: 8),
                  Text("Ingredients: ${data['ingredients'].join(', ')}"),
                  SizedBox(height: 8),
                  Text("Steps:\n${data['steps'].join('\n')}"),
                ],
                SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  child: Text(_isExpanded ? "View Less" : "View More"),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(_isLiked ? Icons.favorite : Icons.favorite_border, color: _isLiked ? Colors.red : null),
                      onPressed: _toggleLike,
                    ),
                    Text("$_likesCount likes"),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
