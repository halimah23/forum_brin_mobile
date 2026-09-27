import 'package:flutter/material.dart';
import 'screens/splash_page.dart';

void main() {
  runApp(const ForumBrinApp());
}

class ForumBrinApp extends StatelessWidget {
  const ForumBrinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BOSDM Connect',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC62828),
        ),
      ),
      home: const SplashPage(),
    );
  }
}