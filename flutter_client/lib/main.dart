import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const ChatApp());
}

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nodi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A0F),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00F5C4),
          secondary: Color(0xFF7C3AED),
          surface: Color(0xFF13131A),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
