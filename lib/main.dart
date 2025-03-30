import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:knowtocook/pages/home_page.dart';
import 'package:knowtocook/pages/notification_page.dart';
import 'package:knowtocook/pages/post_creation.dart';
import 'package:knowtocook/pages/search_page.dart';
import 'package:knowtocook/pages/splashing_screen.dart';
import 'package:knowtocook/pages/user_profile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}
