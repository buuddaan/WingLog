import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Variabler för att hantera sökstatus
  bool _isSearching = false;
  GoogleMapController? _mapController;
  static const String _mapsApiKey = 'AIzaSyBBRoH_10iOdpYF7_FUuEJLay_DGeFq7y8';
  bool _isLoading = false;
  Set<Marker> _markers = {};

  // Kommenterad för tillfället, redo att användas när rutt-ritning ska byggas!
  // Set<Polyline> _polylines = {};

  Future<void> _searchPlace(String query) async {
    setState(() => _isLoading = true);

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(query)}&key=$_mapsApiKey',
    );
    final response = await http.get(url);
    final data = json.decode(response.body);

    if (data['status'] == 'OK') {
      final results = data['results'] as List;

      if (results.isEmpty) {
        // VIKTIGT: Stäng av snurran även om vi inte hittar några resultat!
        setState(() => _isLoading = false);
        return;
      } else {
        if (!mounted) return;
        showModalBottomSheet(
          context: context,
          builder: (_) => ListView.builder(
            itemCount: results.length,
            itemBuilder: (_, i) => ListTile(
              leading: const Icon(Icons.location_on, color: Color(0xFF2D5A27)),
              title: Text(results[i]['formatted_address']),
              onTap: () {
                Navigator.pop(context);
                _goToLocation(results[i]);
              },
            ),
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  void _goToLocation(dynamic result) {
    final loc = result['geometry']['location'];
    final pos = LatLng(loc['lat'], loc['lng']);
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(pos, 13));
    setState(() {
      _markers = {
        Marker(markerId: const MarkerId('search_result'), position: pos)
      };
    });
  }

  Future<void> _drawRoute(LatLng destination) async {
    setState(() {
      _markers = {
        Marker(markerId: const MarkerId('destination'), position: destination),
      };
    });

    final url = 'https://www.google.com/maps/dir/?api=1&destination=${destination.latitude},${destination.longitude}&travelmode=driving';
    final Uri uri = Uri.parse(url);

    if (!await launchUrl(uri)) {
      debugPrint('Kunde inte öppna länken: $url');
    }
  }

  final TextEditingController _searchController = TextEditingController();
  final LatLng _initialPosition = const LatLng(59.3293, 18.0686);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            markers: _markers,
            // Kommenterad för tillfället tills vi börjar använda _polylines
            // polylines: _polylines,
            onTap: (LatLng pos) => _drawRoute(pos),
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: 12,
            ),
          ),

          // DEN INTERAKTIVA SÖKRUTAN
          Positioned(
            top: 20,
            left: 20,
            right: 20, // Gör att den expanderar över hela bredden
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300), // Hastighet på animation
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
              ),
              child: _isSearching
                  ? TextField(
                controller: _searchController,
                autofocus: true, // Öppnar tangentbordet
                decoration: InputDecoration(
                  hintText: 'Sök på plats eller fågel...',
                  border: InputBorder.none,
                  icon: const Icon(Icons.search, color: Color(0xFF2D5A27)),
                  // HÄR ANVÄNDS _isLoading!
                  suffixIcon: _isLoading
                      ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Color(0xFF2D5A27),
                      ),
                    ),
                  )
                      : IconButton(
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
                  _searchPlace(value);
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