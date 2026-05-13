import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/token_service.dart';

//enkel modell för att hålla reda på bildens URL och vilken fågelart (mapp) den tillhör
class BirdPhoto {
  final String imageUrl;
  final String birdSpecies;

  BirdPhoto({required this.imageUrl, required this.birdSpecies});

  factory BirdPhoto.fromJson(Map<String, dynamic> json) {
    return BirdPhoto(
      imageUrl: json['imageUrl'] ?? '',
      // Backend returnerar 'folderName', inte 'birdSpecies'
      birdSpecies: json['folderName'] ?? 'Oidentifierade',
    );
  }
}

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  // Istället för 'File', sparar nu 'BirdPhoto' objekt som hämtas från databasen
  List<BirdPhoto> _photos = [];
  bool _isLoading = true;

  final ImagePicker _picker = ImagePicker();

  // URL till photo-service via API Gateway
  final String _baseUrl = 'http://localhost:8080/gateway/photos';

  @override
  void initState() {
    super.initState();
    _fetchPhotos(); // Ladda bilderna direkt när skärmen öppnas
  }

  // HÄMTA ALLA BILDER FRÅN BACKEND ---
  Future<void> _fetchPhotos() async {
    setState(() => _isLoading = true);
    try {
      final token = await TokenService.getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/my-photos'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _photos = data.map((json) => BirdPhoto.fromJson(json)).toList();
        });
      } else {
        debugPrint("Kunde inte hämta bilder. Status: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Fel vid hämtning av bilder: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // LADDA UPP EN BILD TILL BACKEND ---

  // ÄNDRING: Parametern är nu XFile imageFile
  Future<void> _uploadPhoto(XFile imageFile, String species) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Laddar upp bild...')),
    );

    try {
      final token = await TokenService.getToken();
      final String sessionId = const Uuid().v4();
      final String currentDate = DateTime.now().toIso8601String();

      var uploadRequest = http.MultipartRequest('POST', Uri.parse('$_baseUrl/upload'));
      uploadRequest.headers['Authorization'] = 'Bearer $token';

      uploadRequest.fields['sessionId'] = sessionId;
      uploadRequest.fields['date'] = currentDate;

      // ---- MAGIN FÖR ATT LÖSA FELMEDDELANDET ----
      if (kIsWeb) {
        // På webben läser vi bilden som bytes direkt i webbläsaren
        final bytes = await imageFile.readAsBytes();
        uploadRequest.files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: imageFile.name,
        ));
      } else {
        // På mobil/Mac kan vi fortfarande använda den snabbare fromPath (dart:io)
        uploadRequest.files.add(await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
        ));
      }
      // -------------------------------------------

      var streamedResponse = await uploadRequest.send();

      if (streamedResponse.statusCode == 200 || streamedResponse.statusCode == 201) {
        final saveResponse = await http.put(
          Uri.parse('$_baseUrl/save-to-folder?sessionId=$sessionId&folderName=${Uri.encodeComponent(species)}'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (saveResponse.statusCode == 200) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Bild sparad i ditt galleri!')),
            );
          }
          _fetchPhotos();
        } else {
          throw Exception('Kunde inte spara fågelarten på servern.');
        }
      } else {
        throw Exception('Uppladdningen av bilden misslyckades.');
      }
    } catch (e) {
      debugPrint("Fel vid uppladdning: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fel: $e')));
      }
    }
  }

  // DIALOG FÖR ATT ANGE FÅGELART (MAPP) ---
  // Denna popup visas direkt efter att man valt en bild
  // ÄNDRING: Parametern är nu XFile imageFile
  Future<void> _askForSpeciesAndUpload(XFile imageFile) async {
    String species = '';
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Vilken fågel är detta?'),
          content: TextField(
            onChanged: (value) => species = value,
            decoration: const InputDecoration(hintText: "T.ex. Koltrast"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Avbryt'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Spara och Ladda upp'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (species.isNotEmpty) {
                  // ÄNDRING: Skicka vidare XFile
                  _uploadPhoto(imageFile, species);
                }
              },
            ),
          ],
        );
      },
    );
  }

  // KNAPP-FUNKTIONER
  Future<void> _pickImageFromGallery() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null && mounted) {
      // ÄNDRING: Skickar hela XFile-objektet istället för .path
      _askForSpeciesAndUpload(pickedFile);
    }
  }

  Future<void> _takePicture() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (photo != null && mounted) {
      // ÄNDRING: Skickar hela XFile-objektet istället för .path
      _askForSpeciesAndUpload(photo);
    }
  }

  @override
  Widget build(BuildContext context) {
    //GRUPPERA BILDER EFTER FÅGELART FÖR ATT SKAPA "MAPPAR"
    // Vi bygger en Map där nyckeln är fågelarten, och värdet är en lista med bilder
    Map<String, List<BirdPhoto>> groupedPhotos = {};
    for (var photo in _photos) {
      if (!groupedPhotos.containsKey(photo.birdSpecies)) {
        groupedPhotos[photo.birdSpecies] = [];
      }
      groupedPhotos[photo.birdSpecies]!.add(photo);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: AppBar(
        title: const Text('Mitt Fågelgalleri'),
        backgroundColor: const Color(0xFF2D5A27),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : groupedPhotos.isEmpty
          ? const Center(child: Text('Inga bilder ännu.\nKlicka på + för att lägga till!'))
          : ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: groupedPhotos.keys.length,
        itemBuilder: (context, index) {
          String species = groupedPhotos.keys.elementAt(index);
          List<BirdPhoto> photosForSpecies = groupedPhotos[species]!;

          // Skapa en "Mapp" för varje art
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  species, // Fågelartens namn som rubrik (Mappen)
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D5A27)),
                ),
              ),
              SizedBox(
                height: 120, // Höjd på rullistan för denna fågel
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: photosForSpecies.length,
                  itemBuilder: (context, photoIndex) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          photosForSpecies[photoIndex].imageUrl, // ladda från URL!
                          width: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(),
            ],
          );
        },
      ),

      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "btn_camera",
            onPressed: _takePicture,
            backgroundColor: const Color(0xFF2D5A27),
            child: const Icon(Icons.camera_alt, color: Colors.white),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: "btn_gallery",
            onPressed: _pickImageFromGallery,
            backgroundColor: const Color(0xFF2D5A27),
            child: const Icon(Icons.photo_library, color: Colors.white),
          ),
        ],
      ),
    );
  }
}