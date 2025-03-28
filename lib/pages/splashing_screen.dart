import 'package:flutter/material.dart';
import 'package:knowtocook/pages/login_page.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration(seconds: 50), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()), // Navigate to LoginPage after 3 seconds
      );
    });

    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                _buildImage("https://wallpapers.com/images/hd/aesthetic-food-pictures-2000-x-2667-5tup8wdyceiymfuo.jpg/?food,1", 130),
                Positioned(top: 50, left: 50, child: _buildImage("https://wallpapers.com/images/hd/aesthetic-food-pictures-2000-x-2667-5tup8wdyceiymfuo.jpg?food,2", 80)),
                Positioned(top: 100, right: 30, child: _buildImage("https://wallpapers.com/images/hd/aesthetic-food-pictures-2000-x-2667-5tup8wdyceiymfuo.jpg/?food,3", 90)),
                Positioned(bottom: 80, left: 20, child: _buildImage("https://wallpapers.com/images/hd/aesthetic-food-pictures-2000-x-2667-5tup8wdyceiymfuo.jpg?food,4", 70)),
                Positioned(bottom: 100, right: 50, child: _buildImage("https://wallpapers.com/images/hd/aesthetic-food-pictures-2000-x-2667-5tup8wdyceiymfuo.jpg?food,5", 85)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Start Cooking",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 10),
          const Text(
            "Let's join our community\nto cook better food!",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
              child: const Text("Get Started", style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildImage(String url, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        image: DecorationImage(
          image: NetworkImage(url),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
