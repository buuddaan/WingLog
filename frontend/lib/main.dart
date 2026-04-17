import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'package:camera/camera.dart';
import 'screens/Camera_screen.dart';

//En globallista för kameror
List<CameraDescription> cameras = [];

// async säkerställer att appen väntar tills kameror är identifierade
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cameras = await availableCameras();
  } catch (e){
    print("Kamerafel vid start: $e");
  }
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