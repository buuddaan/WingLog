import 'package:flutter/material.dart';
import 'screens/home_screen.dart';



void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WingLog',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2D5A27),
          primary: const Color(0xFF2D5A27),
          surface: const Color(0xFFF5F5DC),
        ),
      ),
      // Här pekar vi på klassen som ligger i home_screen.dart
      home: const MyHomePage(title: 'WingLog'),
    );
  }
}