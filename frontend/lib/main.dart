import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Winglog',
      theme: ThemeData(
        useMaterial3: true,
        // Färgpalett: Grön, Beige och Vit
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2D5A27), // Skogsgrön
          primary: const Color(0xFF2D5A27),
          surface: const Color(0xFFF5F5DC),   // Beige bakgrund
          secondary: const Color(0xFF4A7044),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F5DC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2D5A27),
          foregroundColor: Colors.white, // Vit text
        ),
      ),
      home: const MyHomePage(title: 'WingLog'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  int _selectedIndex = 0; // Håller koll på vald ikon i bottenmenyn

  void _incrementCounter() => setState(() => _counter++);
  void _decrementCounter() => setState(() => _counter > 0 ? _counter-- : null);

  // Hanterar klick i bottenmenyn
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        // Menyn dyker upp automatiskt till vänster när vi lägger till en 'drawer'
      ),

      // 1. SIDOMENY: Täcker 90% av skärmbredden
      drawer: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Drawer(
          backgroundColor: Colors.white,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: Color(0xFF2D5A27)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.flutter_dash, color: Colors.white, size: 40),
                    SizedBox(height: 10),
                    Text('WingLog Meny', style: TextStyle(color: Colors.white, fontSize: 24)),
                  ],
                ),
              ),
              ListTile(leading: const Icon(Icons.settings), title: const Text('Inställningar'), onTap: () {}),
              ListTile(leading: const Icon(Icons.info), title: const Text('Om WingLog'), onTap: () {}),
            ],
          ),
        ),
      ),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Antal loggade observationer:', style: TextStyle(fontSize: 18)),
            Text(
              '$_counter',
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFF2D5A27)),
            ),
          ],
        ),
      ),

      // 2. KNAPPAR
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20), // Lyft upp dem lite från bottenmenyn
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              onPressed: _decrementCounter,
              backgroundColor: Colors.white,
              child: const Icon(Icons.remove, color: Color(0xFF2D5A27)),
            ),
            const SizedBox(width: 16),
            FloatingActionButton(
              onPressed: _incrementCounter,
              backgroundColor: const Color(0xFF2D5A27),
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ],
        ),
      ),

      // 3. BOTTENMENY (Bottom Navigation Bar)
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF2D5A27),
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          //Ikoner för bottenmeny, finns så många, sök sig fram från "icons.xxxx"
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Karta'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Loggbok'),
          BottomNavigationBarItem(icon: Icon(Icons.forum), label: 'Forum'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}