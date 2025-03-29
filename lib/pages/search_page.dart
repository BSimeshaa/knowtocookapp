import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:knowtocook/pages/home_page.dart';
import 'package:knowtocook/auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:knowtocook/pages/notification_page.dart';
import 'package:knowtocook/pages/post_creation.dart';
import 'package:knowtocook/pages/user_profile.dart';

class SearchPage extends StatefulWidget {

  final String userId;

  const SearchPage({Key? key, required this.userId}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {

  int _selectedIndex = 1;

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
    }else if (index == 4 && currentUser != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserProfilePage(userId: currentUser.uid, currentUserId: currentUser.uid, targetUserId: '',),
        ),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  TextEditingController _searchController = TextEditingController();
  List<String> searchSuggestions = [];
  List<String> recentSearches = [];

  @override
  void initState() {
    super.initState();
    _fetchSearchSuggestions();
    _fetchRecentSearches();
  }

  void _fetchSearchSuggestions() async {
    final snapshot = await FirebaseFirestore.instance.collection('search_suggestions').get();
    setState(() {
      searchSuggestions = snapshot.docs.map((doc) => doc['keyword'] as String).toList();
    });
  }

  void _fetchRecentSearches() async {
    final snapshot = await FirebaseFirestore.instance.collection('recent_searches').orderBy('timestamp', descending: true).limit(5).get();
    setState(() {
      recentSearches = snapshot.docs.map((doc) => doc['query'] as String).toList();
    });
  }

  void _onSearch(String query) async {
    if (query.isNotEmpty) {
      await FirebaseFirestore.instance.collection('recent_searches').add({
        'query': query,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
    // Navigate to search results screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: "Search",
            border: InputBorder.none,
          ),
          onSubmitted: _onSearch,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Recent Searches", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ListView.builder(
              shrinkWrap: true,
              itemCount: recentSearches.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Icon(Icons.history),
                  title: Text(recentSearches[index]),
                  onTap: () => _onSearch(recentSearches[index]),
                );
              },
            ),
            SizedBox(height: 20),
            Text("Search Suggestions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 10,
              children: searchSuggestions.map((suggestion) {
                return ActionChip(
                  label: Text(suggestion),
                  onPressed: () => _onSearch(suggestion),
                );
              }).toList(),
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
}
