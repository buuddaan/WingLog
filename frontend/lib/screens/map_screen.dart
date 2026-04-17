import 'package:flutter/material.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  //Variabler för att hantera sökstatus
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      body: Stack(
        children: [
          InteractiveViewer(
            boundaryMargin: const EdgeInsets.all(100.0),
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.network(
              'https://images.unsplash.com/photo-1524661135-423995f22d0b?auto=format&fit=crop&q=80&w=2000',
              fit: BoxFit.cover,
              width: 2000,
              height: 2000,
              errorBuilder: (context, error, stackTrace) {
                return const Center(child: Text('Kunde inte ladda kartbilden.'));
              },
            ),
          ),

          //DEN INTERAKTIVA SÖKRUTAN
          Positioned(
            top: 20,
            left: 20,
            right: 20, // Gör att den expanderar över hela bredden
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300), // Hastighet på animation, zoomar in lite för att bekräfta att vi nu gör en sök
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
              ),
              child: _isSearching
                  ? TextField(
                controller: _searchController,
                autofocus: true, // Öppnar tangentbordet
                decoration: InputDecoration(
                  hintText: 'Sök på plats eller fågel...', //Ändrar texten här också för att indikera att vi är aktiva i sök
                  border: InputBorder.none,
                  icon: const Icon(Icons.search, color: Color(0xFF2D5A27)),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _isSearching = false;
                        _searchController.clear();
                      });
                    },
                  ),
                ),
                onSubmitted: (value) {
                  // Här kommer kopplingen API in senare
                  debugPrint('Söker efter: $value via API...');
                },
              )
                  : InkWell(
                onTap: () => setState(() => _isSearching = true),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Row(
                    children: const [
                      Icon(Icons.search, color: Color(0xFF2D5A27), size: 20),
                      SizedBox(width: 10),
                      Text('Sök på WingLog...',
                          style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => debugPrint('GPS-funktion kommer senare!'),
        backgroundColor: const Color(0xFF2D5A27),
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }
}