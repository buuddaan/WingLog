import 'package:flutter/material.dart';
import 'logbook_screen.dart';
import 'map_screen.dart';
import 'SoundRecording_screen.dart';
import 'welcome_screen.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;




  static final List<Widget> _pages = <Widget>[  
    const WelcomeScreen(), // Sidan 0: Din nya landningssida
    const MapScreen(),     // Sidan 1: Din interaktiva karta
    const LogbookScreen(), // Sidan 2: Loggboken
    const Center(child: Text('Forum')), // Sidan 3
    const Center(child: Text('Profil')), // Sidan 4
    const SoundRecordingScreen(),
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
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Loggbok'),
          BottomNavigationBarItem(icon: Icon(Icons.forum), label: 'Forum'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: 'Spela in'),

        ],
      ),
    );
  }
}