import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:knowtocook/pages/home_page.dart';
import 'package:knowtocook/pages/login_page.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {

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
  File? _newProfileImage;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }
  int _selectedIndex = 0;

  // List of screens to display based on BottomNavigationBar selection
  final List<Widget> _screens = [
    // Add other screens here
    Center(child: Text("Home Screen")),
    Center(child: Text("Search Screen")),
    Center(child: Text("Post Screen")),
    Center(child: Text("Notification Screen")),
  ];

  // Method to handle navigation when a BottomNavigationBar item is tapped
  void _onItemTapped(int index) async {
    if (index == 0) {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(),
          ),
        );
      }
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }
  // Load user profile data from Firestore
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

  // Function to sign out the user
  Future<void> _signOut() async {
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()), // Redirect to login
    );
  }

  // Function to select and upload a new profile picture
  Future<void> _updateProfilePicture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() {
      _newProfileImage = File(image.path);
    });

    try {
      String userId = _auth.currentUser!.uid;
      TaskSnapshot uploadTask =
      await _storage.ref('profile_images/$userId.jpg').putFile(_newProfileImage!);
      String newProfileImageUrl = await uploadTask.ref.getDownloadURL();

      await _firestore.collection('users').doc(userId).update({
        'profileImage': newProfileImageUrl,
      });

      setState(() {
        profileImageUrl = newProfileImageUrl;
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
                    onTap: _updateProfilePicture,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: profileImageUrl.isNotEmpty
                          ? NetworkImage(profileImageUrl)
                          : const AssetImage("assets/default_avatar.png") as ImageProvider,
                      child: const Align(
                        alignment: Alignment.bottomRight,
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.blue,
                          child: Icon(Icons.camera_alt, size: 16, color: Colors.white),
                        ),
                      ),
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
                    height: 300, // Adjust based on content
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
        currentIndex: 4, // Profile tab selected
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

  // Helper function to display user stats
  Widget _buildStatColumn(String label, int count) {
    return Column(
      children: [
        Text("$count", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }

  // Function to build the user's recipes list
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

  // Function to build the liked recipes list
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
