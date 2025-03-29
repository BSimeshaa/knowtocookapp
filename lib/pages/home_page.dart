import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:knowtocook/pages/notification_page.dart';
import 'package:knowtocook/pages/post_creation.dart';
import 'package:knowtocook/pages/search_page.dart';
import 'package:knowtocook/pages/user_profile.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required String userId});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  int _selectedIndex = 0;

  void _onIconClicked(int _selectedIndex) async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (_selectedIndex== 4 && currentUser != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => UserProfilePage(userId: currentUser.uid, currentUserId: currentUser.uid, targetUserId: currentUser.uid,)),
      );
    } else if (_selectedIndex == 2 && currentUser != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => RecipeCreationPage(userId: currentUser.uid)),
      );
    } else if (_selectedIndex == 3 && currentUser != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => NotificationsPage(userId: currentUser.uid, currentUserId: currentUser.uid, targetUserId: '',)),
      );
    } else if (_selectedIndex == 1 && currentUser != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SearchPage(userId: currentUser.uid)),
      );
    } else {
      setState(() {
        _selectedIndex = _selectedIndex;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Home"), backgroundColor: Colors.white, elevation: 0),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: "Search",
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            SizedBox(height: 16),
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance.collection('recipes').orderBy('timestamp', descending: true).snapshots(),
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
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle, size: 40), label: "Post"),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: "Notification"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
        onTap: _onIconClicked,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,

      ),
    );
  }
}

class RecipeCard extends StatefulWidget {
  final QueryDocumentSnapshot recipe;

  RecipeCard({required this.recipe});

  @override
  _RecipeCardState createState() => _RecipeCardState();
}

class _RecipeCardState extends State<RecipeCard> {
  bool _isExpanded = false;

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
              ],
            ),
          ),
        ],
      ),
    );

  }
}
