import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:knowtocook/pages/login_page.dart';
import 'package:knowtocook/pages/home_page.dart';
import 'package:knowtocook/pages/recipe_details_page.dart'; // Import the HomePage

class UserProfilePage extends StatefulWidget {
  final String userId;
  final String currentUserId;
  final String targetUserId;

  const UserProfilePage({
    super.key,
    required this.userId,
    required this.currentUserId,
    required this.targetUserId,
  });

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
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(
          widget.userId).get();

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
      MaterialPageRoute(builder: (context) =>
          LoginPage()), // Make sure LoginPage is properly defined
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
            decoration: InputDecoration(
                hintText: "https://example.com/image.jpg"),
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

  // Navigate to home page when back button is clicked
  void _navigateToHomePage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) =>
          HomePage(userId: widget.userId)), // Pass userId if needed
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        // Remove the default back button
        title: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back), // Custom back arrow
              onPressed: _navigateToHomePage, // Navigate to HomePage
            ),
            Text("Profile",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.red), // Sign-out icon
            onPressed: _signOut, // Call your sign-out method
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
                borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30)),
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
                          : AssetImage(
                          'assets/default_avatar.png') as ImageProvider,
                      radius: 50,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(username, style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(bio, style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [],
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
                    height: 500,
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

  Widget _buildUserRecipes() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('recipes')
          .where('userId', isEqualTo: widget.userId) // Query by userId field
          .snapshots(), // Use snapshots() to listen to real-time updates
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No recipes found."));
        }

        // Debugging: Log the length of documents fetched
        print("Number of recipes fetched: ${snapshot.data!.docs.length}");

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

            // Debugging: Log the content of the recipe document
            print("Recipe at index $index: ${recipe.data()}");

            return _buildRecipeCard(recipe, index); // Display each recipe with delete option
          },
        );
      },
    );
  }


  Widget _buildRecipeCard(QueryDocumentSnapshot recipe, int index) {
    var data = recipe.data() as Map<String, dynamic>;

    // Safely access the fields from Firestore data
    String title = data['foodName'] ??
        'No Title'; // Provide a default value if 'foodName' is missing
    String imageUrl = data['imageUrl'] ??
        ''; // Default to empty string if no imageUrl
    String description = data['description'] ??
        'No Description'; // Default to 'No Description'
    String recipeId = recipe.id; // Get the recipe ID

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          Expanded(
            child: imageUrl.isNotEmpty
                ? Image.network(
              imageUrl,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                    child: Icon(Icons.error)); // In case the image is broken
              },
            )
                : const Center(child: Icon(Icons
                .image_not_supported)), // Display when no image URL is provided
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              title, // Display the recipe title
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              description, // Display description, or show a default text
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          // "Delete" Button Section
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () async {
                // Confirm before deleting
                bool confirmDelete = await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text("Delete Recipe"),
                      content: Text(
                          "Are you sure you want to delete this recipe?"),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text("Delete"),
                        ),
                      ],
                    );
                  },
                ) ?? false;

                if (confirmDelete) {
                  try {
                    // Delete the recipe document from Firestore
                    await _firestore.collection('recipes')
                        .doc(recipeId)
                        .delete();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Recipe deleted successfully")),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Failed to delete recipe: $e")),
                    );
                  }
                }
              },
              child: Text("Delete"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Set button color to red
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildLikedRecipes() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('recipes') // Fetch recipes collection
          .where('likes', arrayContains: widget
          .userId) // Check if the userId is in the 'likes' array
          .orderBy('timestamp',
          descending: true) // Ensure recipes are sorted by timestamp
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No liked recipes found."));
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
            return _buildRecipeCard01(
                recipe); // Display each liked recipe in a card
          },
        );
      },
    );
  }

  Widget _buildRecipeCard01(QueryDocumentSnapshot recipe) {
    var data = recipe.data() as Map<String, dynamic>;

    // Safely access the fields from Firestore data
    String title = data['foodName'] ??
        'No Title'; // Provide a default value if 'foodName' is missing
    String imageUrl = data['imageUrl'] ??
        ''; // Default to empty string if no imageUrl
    String description = data['description'] ??
        'No Description'; // Default to 'No Description'
    String recipeId = recipe.id; // Get the recipe ID

    // Check if the current user has liked the recipe
    bool isLiked = data['likes'].contains(
        FirebaseAuth.instance.currentUser!.uid);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section with fixed height
          imageUrl.isNotEmpty
              ? Container(
            height: 60, // Adjust height to fit the image better
            width: double.infinity,
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                    child: Icon(Icons.error)); // In case the image is broken
              },
            ),
          )
              : const Center(child: Icon(Icons.image_not_supported)),
          // Display when no image URL is provided

          // Title Section
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              title, // Display the recipe title
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),

          // Description Section
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Text(
              description, // Display description, or show a default text
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),

// "Cook" Button Section - Show only for liked recipes
          if (isLiked) ...[
            Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 1.0, bottom: 1.0), // Adjust padding to reduce space
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to RecipeDetailsPage, passing the recipeId
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RecipeDetailsPage(recipeId: recipeId),
                    ),
                  );
                },
                child: Text("Cook"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, // Set button color
                ),
              ),
            ),
          ],

        ],
      ),
    );
  }
}