import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/saved_novels_screen.dart';
import 'screens/novel_details_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/saved': (context) => const SavedNovelsScreen(),
        '/details': (context) => const NovelDetailsScreen(),
      },
    );
  }
}
