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

  // Pins för aktiv artsökning (null = inget filter)
  Set<Marker>? _filteredSightingMarkers;
  String? _activeSpeciesFilter;

  // Styr om användaren är i "placera pin"-läge (aktiveras via +-knappen)
  bool _placingPin = false;
  bool _canPlace = false;

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
    if (!_placingPin || !_canPlace) return;
    setState(() { _placingPin = false; _canPlace = false; });

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

  // Söker både fågelarter (backend) och platser (Geocoding API) parallellt
  Future<void> _search(String query) async {
    setState(() => _isLoading = true);

    final speciesFuture = GeoService.searchBySpecies(query).catchError((_) => <Sighting>[]);
    final geoFuture = _geocode(query);

    final sightings = await speciesFuture;
    final places = await geoFuture;

    if (!mounted) return;

    if (sightings.isNotEmpty) {
      setState(() {
        _activeSpeciesFilter = query;
        _filteredSightingMarkers = sightings.map((s) => Marker(
          markerId: MarkerId('filtered_${s.id}'),
          position: LatLng(s.latitude, s.longitude),
          infoWindow: InfoWindow(title: s.speciesName, snippet: s.description),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          onTap: () => _showSightingOptions(s),
        )).toSet();
      });
    }

    if (places.isNotEmpty) {
      showModalBottomSheet(
        context: context,
        builder: (_) => ListView.builder(
          itemCount: places.length,
          itemBuilder: (_, i) => ListTile(
            leading: const Icon(Icons.location_on, color: Color(0xFF2D5A27)),
            title: Text(places[i]['formatted_address']),
            onTap: () {
              Navigator.pop(context);
              _goToLocation(places[i]);
            },
          ),
        ),
      );
    }

    setState(() => _isLoading = false);
  }

  Future<List<dynamic>> _geocode(String query) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(query)}&key=$_mapsApiKey',
    );
    final response = await http.get(url);
    final data = json.decode(response.body);
    if (data['status'] == 'OK') return data['results'] as List;
    return [];
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
            markers: {..._markers, ...(_filteredSightingMarkers ?? _sightingMarkers)},
            onTap: _onMapTap,
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: 12,
            ),
          ),

          // Filterchip som visas när artsökning är aktiv
          if (_activeSpeciesFilter != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 190,
              left: 16,
              child: Chip(
                backgroundColor: const Color(0xFF2D5A27),
                label: Text(
                  _activeSpeciesFilter!,
                  style: const TextStyle(color: Colors.white),
                ),
                deleteIconColor: Colors.white,
                onDeleted: () => setState(() {
                  _activeSpeciesFilter = null;
                  _filteredSightingMarkers = null;
                }),
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
                  color: const Color(0xFF081145),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tryck på kartan för att placera pin',
                        style: TextStyle(color: Colors.white)),
                    GestureDetector(
                      onTap: () => setState(() { _placingPin = false; _canPlace = false; }),
                      child: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

          // DE TVÅ KNAPPARNA (Sök, Placera Pin) SAMLADE UNDER HAMBURGERMENYN
          Positioned(
            top: MediaQuery.of(context).padding.top + 9, // Tryckt ner 72px för att ge plats åt Flutters egna menyknapp
            left: 9,
            right: 9, // right: 16 gör att sökfältet vet hur brett det får lov att bli när det expanderar
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // 1. Sökfältet
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  height: 48,
                  // Om vi söker tar vi upp skärmens bredd (minus marginaler). Annars 48px för en cirkel.
                  width: _isSearching ? MediaQuery.of(context).size.width - 32 : 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF081145), // Mörk transparent färg
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width - 32,
                        height: 48,
                        child: _isSearching
                            ? TextField(
                                controller: _searchController,
                                autofocus: true,
                                style: const TextStyle(color: Colors.white), // Vit text när man skriver
                                decoration: InputDecoration(
                                  hintText: 'Sök på plats eller fågel...',
                                  hintStyle: const TextStyle(color: Colors.white70), // Ljusgrå hint-text
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  suffixIcon: _isLoading
                                      ? const Padding(
                                          padding: EdgeInsets.all(12.0),
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.white, // Vit laddningshjul
                                            ),
                                          ),
                                        )
                                      : IconButton(
                                          icon: const Icon(Icons.close, color: Colors.white),
                                          onPressed: () {
                                            setState(() {
                                              _isSearching = false;
                                              _searchController.clear();
                                            });
                                          },
                                        ),
                                ),
                                onSubmitted: _search,
                              )
                            : Align(
                                alignment: Alignment.centerLeft,
                                child: SizedBox(
                                  width: 48,
                                  child: IconButton(
                                    icon: const Icon(Icons.search, color: Colors.white),
                                    onPressed: () {
                                      setState(() {
                                        _isSearching = true;
                                      });
                                    },
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 2. Placera Pin-knapp
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF081145),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.pin_drop_outlined, color: Colors.white),
                    onPressed: () {
                      setState(() { _placingPin = true; _canPlace = false; });
                      Future.delayed(const Duration(milliseconds: 400), () {
                        if (mounted) setState(() => _canPlace = true);
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}