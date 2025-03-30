import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:knowtocook/pages/home_page.dart'; // Import HomePage
import 'package:knowtocook/pages/recipe_details_page.dart'; // Import the Recipe Details Page

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController searchController = TextEditingController();
  String searchQuery = ''; // For search query
  bool showFilter = false;
  List<String> recentSearches = [
    "Pancakes",
    "Salad"
  ]; // Example recent searches
  List<String> searchSuggestions = [
    "sushi",
    "sandwich",
    "seafood",
    "fried rice"
  ];

  // Search function based on user input
  Future<QuerySnapshot> _searchRecipes() async {
    return await FirebaseFirestore.instance
        .collection('recipes')
        .where('foodName',
        isGreaterThanOrEqualTo: searchQuery) // Search recipes by name
        .where('foodName',
        isLessThanOrEqualTo: '$searchQuery\uf8ff') // Ensure search works with a prefix
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => HomePage(userId: 'user123')), // Navigate to HomePage
                );
              },
            ),
            Text("Search",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: "Search",
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          searchController.clear();
                          searchQuery = '';
                        });
                      },
                    )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onChanged: (text) {
                    setState(() {
                      searchQuery = text;
                    });
                  },
                ),
                SizedBox(height: 10),
                // Search results
                Expanded(
                  child: FutureBuilder<QuerySnapshot>(
                    future: _searchRecipes(),
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

                      return GridView.builder(
                        padding: const EdgeInsets.all(10),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 1,
                          crossAxisSpacing: 40,
                          mainAxisSpacing: 40,
                        ),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          var recipe = snapshot.data!.docs[index];
                          return _buildRecipeCard(recipe);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(QueryDocumentSnapshot recipe) {
    var data = recipe.data() as Map<String, dynamic>;

    String title = data['foodName'] ?? 'No Title';
    String imageUrl = data['imageUrl'] ?? '';
    String description = data['description'] ?? 'No Description';
    String recipeId = recipe.id;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section with a fixed size
          Container(
            height: 150, // Fixed height for the image
            width: double.infinity,
            child: imageUrl.isNotEmpty
                ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Center(child: Icon(Icons.image_not_supported));
              },
            )
                : const Center(child: Icon(Icons.image_not_supported)),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              description,
              style: TextStyle(color: Colors.grey[600]),
              overflow: TextOverflow.ellipsis,
              maxLines: 4, // Limit description to 2 lines
            ),
          ),
          // Spacer to push button to the bottom
          Spacer(),
          // Cook Button Section
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Align(
              alignment: Alignment.bottomRight, // Align button to bottom-right
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to RecipeDetailsPage with the recipeId
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          RecipeDetailsPage(recipeId: recipeId),
                    ),
                  );
                },
                child: Text("Cook"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
