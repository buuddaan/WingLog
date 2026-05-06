import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/geo_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Styr om sökfältet är aktivt (expanderat) eller visar platshållartext
  bool _isSearching = false;

  // Kontrollerar Google Maps-kartan, t.ex. för att flytta kameran
  GoogleMapController? _mapController;

  // API-nyckel för Google Maps (Geocoding). Används vid platssökning.
  static const String _mapsApiKey = 'AIzaSyBBRoH_10iOdpYF7_FUuEJLay_DGeFq7y8';

  // Visar en laddningsspinner i sökfältet medan sökning pågår
  bool _isLoading = false;

  // Pins från platssökning (visas när användaren söker en adress)
  Set<Marker> _markers = {};

  // Pins från sparade fågelobservationer (laddas från backend vid start)
  Set<Marker> _sightingMarkers = {};

  // Styr om användaren är i "placera pin"-läge (aktiveras via +-knappen)
  bool _placingPin = false;

  @override
  void initState() {
    super.initState();
    // Hämta befintliga observationer från backend och visa dem som pins
    _loadSightings();
  }

  // Hämtar alla sparade fågelobservationer från geo-service via GeoService
  // och omvandlar dem till gröna pins på kartan
  Future<void> _loadSightings() async {
    try {
      final sightings = await GeoService.getSightings();
      setState(() {
        _sightingMarkers = sightings.map((s) => Marker(
          markerId: MarkerId('sighting_${s.id}_${s.latitude}_${s.longitude}'),
          position: LatLng(s.latitude, s.longitude),
          infoWindow: InfoWindow(title: s.speciesName, snippet: s.description),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          onTap: () => _showSightingOptions(s),
        )).toSet();
      });
    } catch (_) {
      // Om backend inte är tillgänglig visas inga pins — appen kraschar inte
    }
  }

  // Visas när användaren trycker på en befintlig observation-pin
  // Ger möjlighet att ta bort observationen
  Future<void> _showSightingOptions(Sighting s) async {
    final delete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.speciesName),
        content: Text(s.description ?? 'Ingen beskrivning'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Stäng')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ta bort', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (delete == true) {
      try {
        await GeoService.deleteSighting(s.id);
        await _loadSightings();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Kunde inte ta bort: $e')),
          );
        }
      }
    }
  }

  // Anropas när användaren trycker på kartan.
  // Gör inget om "placera pin"-läget inte är aktivt.
  // Om läget är aktivt: stänger läget, öppnar dialog för att fylla i art och beskrivning.
  Future<void> _onMapTap(LatLng pos) async {
    if (!_placingPin) return;
    setState(() => _placingPin = false);

    final speciesController = TextEditingController();
    final descController = TextEditingController();

    // barrierDismissible: false = dialogen stängs BARA via knapparna, inte genom att
    // trycka utanför. Det förhindrar att kartan råkar ta emot trycket och öppnar dialogen igen.
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Ny observation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: speciesController,
              decoration: const InputDecoration(labelText: 'Fågelart *'),
              autofocus: true,
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Beskrivning (valfritt)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Avbryt')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Spara')),
        ],
      ),
    );

    // Spara bara om användaren tryckte Spara och fyllde i ett artnamn
    if (confirmed == true && speciesController.text.trim().isNotEmpty) {
      try {
        // Skickar koordinater + artnamn + beskrivning till geo-service via GeoService
        await GeoService.createSighting(
          latitude: pos.latitude,
          longitude: pos.longitude,
          speciesName: speciesController.text.trim(),
          description: descController.text.trim().isEmpty ? null : descController.text.trim(),
        );
        // Ladda om alla pins så den nya observationen syns direkt
        await _loadSightings();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Kunde inte spara: $e')),
          );
        }
      }
    }
  }

  // Söker efter en plats via Google Geocoding API och visar en lista med träffar
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
        setState(() => _isLoading = false);
        return;
      }
      if (!mounted) return;
      // Visar sökresultaten i en lista längst ned på skärmen
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

    setState(() => _isLoading = false);
  }

  // Flyttar kameran till vald plats och sätter en röd sökpin där
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

  // Styr texten i sökfältet
  final TextEditingController _searchController = TextEditingController();

  // Startposition för kartan (Stockholm)
  final LatLng _initialPosition = const LatLng(59.3293, 18.0686);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      body: Stack(
        children: [
          // Själva Google Maps-kartan
          GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            // Kombinerar sökpins (röda) och observationspins (gröna)
            markers: {..._markers, ..._sightingMarkers},
            onTap: _onMapTap,
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: 12,
            ),
          ),

          // Banner som visas längst ned när "placera pin"-läget är aktivt
          if (_placingPin)
            Positioned(
              bottom: 100,
              left: 40,
              right: 40,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D5A27),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tryck på kartan för att placera pin',
                        style: TextStyle(color: Colors.white)),
                    // Avbryt-knapp som stänger "placera pin"-läget
                    GestureDetector(
                      onTap: () => setState(() => _placingPin = false),
                      child: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

          // Sökfältet längst upp — animeras mellan komprimerat och aktivt läge
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
              ),
              // Visar antingen ett aktivt textfält eller en klickbar platshållare
              child: _isSearching
                  ? TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Sök på plats eller fågel...',
                        border: InputBorder.none,
                        icon: const Icon(Icons.search, color: Color(0xFF2D5A27)),
                        // Spinner medan sökning pågår, annars stäng-knapp
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
                      onSubmitted: _searchPlace,
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
      // Två knappar längst ned till höger:
      // + för att lägga till en observation, GPS för platsfunktion (ej implementerad än)
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'add_observation',
            onPressed: () => setState(() => _placingPin = true),
            backgroundColor: const Color(0xFF2D5A27),
            child: const Icon(Icons.add, color: Colors.white),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'gps',
            onPressed: () => debugPrint('GPS-funktion kommer senare!'),
            backgroundColor: const Color(0xFF2D5A27),
            child: const Icon(Icons.my_location, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
