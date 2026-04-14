import 'package:flutter/material.dart';
import 'logbook_screen.dart';
import 'map_screen.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    const Center(child: Text('Karta - kopplas till Nominatim snart')),
    const LogbookScreen(),
    const Center(child: Text('Forum')),
    const Center(child: Text('Profil')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        // Ikonen dyker upp automatiskt när 'drawer' har ett innehåll
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
        // VIKTIGT: Alla ikoner syns samtidigt
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF2D5A27), // Grön när vald
        unselectedItemColor: Colors.grey,           // Grå när ej vald
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Karta'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Loggbok'),
          BottomNavigationBarItem(icon: Icon(Icons.forum), label: 'Forum'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}