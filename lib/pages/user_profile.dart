import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:knowtocook/pages/home_page.dart';
import 'package:knowtocook/pages/login_page.dart';
import 'package:knowtocook/pages/notification_page.dart';
import 'package:knowtocook/pages/post_creation.dart';
import 'package:knowtocook/pages/search_page.dart';

class UserProfilePage extends StatefulWidget {
  final String userId;
  final String currentUserId;
  final String targetUserId;

  const UserProfilePage({Key? key, required this.userId, required this.currentUserId, required this.targetUserId}) : super(key: key);

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {

  int _selectedIndex = 4;

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
    } else if (index == 3 && currentUser != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NotificationsPage(userId: currentUser.uid, currentUserId: currentUser.uid, targetUserId: '',),
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
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String username = "";
  String bio = "";
  String profileImageUrl = "";
  int recipes = 0;
  int following = 0;
  int followers = 0;
  bool isLoading = true;


  // loads user's data from db
  Future<void> _loadUserProfile() async {
    try {
      DocumentSnapshot userDoc =
      await _firestore.collection('users').doc(widget.userId).get();

      if (userDoc.exists) {
        setState(() {
          username = userDoc['name'];
          bio = userDoc['bio'];
          profileImageUrl = userDoc['profileImage'];
          recipes = userDoc['recipes'];
          following = userDoc['following'];
          followers = userDoc['followers'];
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading user profile: $e");
    }
  }

  // method to sign out from the profile
  Future<void> _signOut() async {
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  Future<String?> _showImageUrlDialog(BuildContext context) async {
    TextEditingController controller = TextEditingController();
    return await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Enter Image URL"),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: "https://example.com/image.jpg"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: Text("Update"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateProfilePicture(String imageUrl) async {
    try {
      String userId = _auth.currentUser!.uid;

      await _firestore.collection('users').doc(userId).update({
        'profileImage': imageUrl,
      });

      setState(() {
        profileImageUrl = imageUrl;
      });
    } catch (e) {
      print("Error updating profile picture: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _signOut, // Sign Out Function
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 3,
                  ),
                ],
                borderRadius:
                const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  GestureDetector(
                  onTap: () async {
                    String? imageUrl = await _showImageUrlDialog(context);
                    if (imageUrl != null && imageUrl.isNotEmpty) {
                    _updateProfilePicture(imageUrl);
                    }
                    },
                      child: CircleAvatar(
                        backgroundImage: profileImageUrl.isNotEmpty
                            ? NetworkImage(profileImageUrl)
                            : AssetImage('assets/default_avatar.png') as ImageProvider,
                        radius: 50,
                      ),
                    ),
                  const SizedBox(height: 10),
                  Text(username, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(bio, style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatColumn("Recipes", recipes),
                      _buildStatColumn("Following", following),
                      _buildStatColumn("Followers", followers),
                    ],
                  ),
                ],
              ),
            ),

            // Tabs Section (Recipes & Liked)
            DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.green,
                    tabs: [
                      Tab(text: "Recipes"),
                      Tab(text: "Liked"),
                    ],
                  ),
                  SizedBox(
                    height: 300,
                    child: TabBarView(
                      children: [
                        _buildUserRecipes(),
                        _buildLikedRecipes(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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


  Widget _buildStatColumn(String label, int count) {
    return Column(
      children: [
        Text("$count", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }

  // user's recipes list
  Widget _buildUserRecipes() {
    return FutureBuilder(
      future: _firestore.collection('recipes').where('userId', isEqualTo: widget.userId).get(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No recipes found."));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(10),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var recipe = snapshot.data!.docs[index];
            return _buildRecipeCard(recipe);
          },
        );
      },
    );
  }

  //  liked recipes list
  Widget _buildLikedRecipes() {
    return const Center(child: Text("Liked Recipes will be shown here."));
  }


  // Recipe Card UI
  Widget _buildRecipeCard(QueryDocumentSnapshot recipe) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Image.network(recipe['imageUrl'], width: double.infinity, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(recipe['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}




