import 'package:flutter/material.dart';
import '../core/theme/app_gradients.dart';
import 'map_screen.dart';
import 'camera_screen.dart';
import '../main.dart'; // För 'cameras'-variabeln
import 'sound_recording_screen.dart';
import 'gallery_screen.dart';
import 'profile_screen.dart'; // Vår nya profilsida!
import '../design_system/organisms/app_bottom_nav.dart';


class MainLayout extends StatefulWidget {
  final VoidCallback onLogout;

  const MainLayout({super.key, required this.onLogout});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  // Startar på index 0 (Kameran!)
  int _selectedIndex = 1;

  late final List<Widget> _pages = [
    const MapScreen(),              // Index 0: Karta
    CameraScreen(cameras: cameras), // Index 1: Kamera
    const GalleryScreen(),          // Index 2: Galleri
    const SoundRecordingScreen(),   // Index 3: Spela in ljud
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.white, shadows: [Shadow(color: Colors.black, blurRadius: 10)]), // Vit menyikon så den syns på kameran
      ),

      // 1. DRAWER (MENY)
      drawer: SizedBox(
        width: MediaQuery.of(context).size.width * 0.85,
        child: Drawer(
          backgroundColor: const Color(0xFFF4FFFD),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(
                    gradient: AppGradients.loginBackground
                ),
                child: Text(
                  'WingLog',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.account_circle, color: Color(0xFF081145)),
                title: const Text('Min Profil / Inställningar'),
                onTap: () {
                  Navigator.pop(context); // Stäng menyn
                  // Öppna profilsidan
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(onLogout: widget.onLogout)));
                },
              ),
            ],
          ),
        ),
      ),

      body: _pages[_selectedIndex],

      // 2. BOTTOM NAVIGATION BAR
      bottomNavigationBar: AppBottomNav(
        selectedIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}