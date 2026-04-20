import 'package:flutter/material.dart';
import 'logbook_screen.dart'; // Inte aktiv
import 'map_screen.dart';
import 'Camera_screen.dart';
import '../main.dart';
import 'community_screen.dart';
import 'SoundRecording_screen.dart';
import 'welcome_screen.dart';

class MyHomePage extends StatefulWidget {
  // Lägg till onLogout här:
  final VoidCallback onLogout;

  // Uppdatera konstruktorn för att kräva den:
  const MyHomePage({super.key, required this.title, required this.onLogout});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;




  late final List<Widget> _pages = <Widget>[
    // SIDAN 0: Byt ut WelcomeScreen mot en enkel inloggad vy
    const Center(
      child: Text(
        'Välkommen till WingLog!\n\nDu är nu inloggad.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 20, color: Color(0xFF2D5A27), fontWeight: FontWeight.bold),
      ),
    ),
    const MapScreen(),     // Sidan 1: Din interaktiva karta
    CameraScreen(cameras: cameras), // Sidan 2: Kamera (OBS: Kräver att 'cameras' är definierad)
    const CommunityScreen(), // Sidan 3: Forum
    const Center(child: Text('Profil')), // Sidan 4: Profil
    const SoundRecordingScreen(), // Sidan 5: Ljudinspelning
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
      ),

      // 1. DRAWER (MENY)
      drawer: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(color: Color(0xFF2D5A27)),
                child: Text('WingLog Meny', style: TextStyle(color: Colors.white, fontSize: 24)),
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Inställningar'),
                onTap: () => Navigator.pop(context),
              ),
              // --- NY KOD BÖRJAR HÄR ---
              const Divider(), // En liten visuell avdelare
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logga ut', style: TextStyle(color: Colors.red)),
                onTap: () {
                  // Stäng menyn först
                  Navigator.pop(context);
                  // Anropa utloggningsfunktionen från main.dart
                  widget.onLogout();
                },
              ),
              // --- NY KOD SLUTAR HÄR ---
            ],
          ),
        ),
      ),

      body: _pages[_selectedIndex],

      // 2. BOTTOM NAVIGATION BAR
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF2D5A27),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Hem'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Karta'),
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: 'Kamera'),
          BottomNavigationBarItem(icon: Icon(Icons.forum), label: 'Forum'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: 'Spela in'),

        ],
      ),
    );
  }
}