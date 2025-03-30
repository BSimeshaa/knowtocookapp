import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:knowtocook/pages/login_page.dart';

class UserProfilePage extends StatefulWidget {
  final String userId;
  final String currentUserId;
  final String targetUserId;

  const UserProfilePage({super.key, required this.userId, required this.currentUserId, required this.targetUserId});

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String username = "";
  String bio = "";
  String profileImageUrl = "";
  int recipes = 0;
  int following = 0;
  int followers = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(widget.userId).get();

      if (userDoc.exists) {
        setState(() {
          username = userDoc['name'] ?? '';
          bio = userDoc['bio'] ?? '';
          profileImageUrl = userDoc['profileImage'] ?? '';
          recipes = userDoc['recipes'] ?? 0;
          following = userDoc['following'] ?? 0;
          followers = userDoc['followers'] ?? 0;
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading user profile: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  // Method to sign out from the profile
  Future<void> _signOut() async {
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()), // Make sure LoginPage is properly defined
    );
  }


  Future<void> _updateProfilePicture(String imageUrl) async {
    try {
      await _firestore.collection('users').doc(widget.userId).update({
        'profileImage': imageUrl,
      });

      setState(() {
        profileImageUrl = imageUrl;
      });
    } catch (e) {
      print("Error updating profile picture: $e");
    }
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

                    ],
                  ),
                ],
              ),
            ),
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


  //recipe card
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