import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart';

import 'package:camera/camera.dart';

List<CameraDescription> cameras = []; // Denna variabel ropar home_screen.dart på!

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cameras = await availableCameras();
  } catch (e) {
    debugPrint("Kunde inte starta kameran: $e");
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // 1. Variabeln som styr om vi ser Login eller Homepage
  bool _isLoggedIn = false;

  // 2. Funktion som anropas från WelcomeScreen vid lyckad inloggning/reg
  void _handleLoginSuccess() {
    setState(() {
      _isLoggedIn = true;
    });
  }
  void _handleLogout() {
    setState(() {
      _isLoggedIn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WingLog',
      debugShowCheckedModeBanner: false, // Tar bort debug-banderollen
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2D5A27), // Din Skogsgröna
          primary: const Color(0xFF2D5A27),
          surface: const Color(0xFFF5F5DC),   // Din Beige
        ),
      ),

      // 3. LOGIKEN: Om inloggad -> Hem, annars -> Welcome (Login)
      home: _isLoggedIn
          ? MyHomePage(
        title: 'WingLog',
        onLogout: _handleLogout, // Skickar med funktionen för att logga ut
      )
          : WelcomeScreen(
        onLoginSuccess: _handleLoginSuccess, // Skickar med funktionen för lyckad inloggning
      ),
    );
  }
}