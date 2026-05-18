import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/token_service.dart';

// --- Design System Importer ---
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../design_system/atoms/app_text.dart';
import '../design_system/molecules/collection_card.dart';
import '../design_system/atoms/camera_icon_button.dart';
import 'folder_details_screen.dart';

// Enkel modell för att hålla reda på bildens URL och vilken fågelart (mapp) den tillhör
class BirdPhoto {
  final String id;
  final String imageUrl;
  final String birdSpecies;

  BirdPhoto({required this.id, required this.imageUrl, required this.birdSpecies});

  factory BirdPhoto.fromJson(Map<String, dynamic> json) {
    return BirdPhoto(
      id: json['id'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
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
  List<BirdPhoto> _photos = [];
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();
  final String _baseUrl = 'http://localhost:8080/gateway/photos';

  @override
  void initState() {
    super.initState();
    _fetchPhotos();
  }

  // --- NÄTVERKSANROP (Samma som innan) ---
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

      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        uploadRequest.files.add(http.MultipartFile.fromBytes('file', bytes, filename: imageFile.name));
      } else {
        uploadRequest.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
      }

      var streamedResponse = await uploadRequest.send();

      if (streamedResponse.statusCode == 200 || streamedResponse.statusCode == 201) {
        final saveResponse = await http.put(
          Uri.parse('$_baseUrl/save-to-folder?sessionId=$sessionId&folderName=${Uri.encodeComponent(species)}'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (saveResponse.statusCode == 200) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bild sparad i ditt galleri!')));
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fel: $e')));
    }
  }

  Future<void> _askForSpeciesAndUpload(XFile imageFile) async {
    String species = '';
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        // Här kan vi också snygga till med AppColors!
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const AppText.title('Vilken fågel är detta?'),
          content: TextField(
            onChanged: (value) => species = value,
            decoration: const InputDecoration(hintText: "T.ex. Koltrast"),
          ),
          actions: <Widget>[
            TextButton(
              child: const AppText.label('Avbryt'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const AppText.label('Spara och Ladda upp', color: AppColors.brandSecondaryDark),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (species.isNotEmpty) _uploadPhoto(imageFile, species);
              },
            ),
          ],
        );
      },
    );
  }

  // --- KNAPPAR ---
  Future<void> _pickImageFromGallery() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null && mounted) _askForSpeciesAndUpload(pickedFile);
  }

  Future<void> _takePicture() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (photo != null && mounted) _askForSpeciesAndUpload(photo);
  }

  @override
  Widget build(BuildContext context) {
    Map<String, List<BirdPhoto>> groupedPhotos = {};
    for (var photo in _photos) {
      if (!groupedPhotos.containsKey(photo.birdSpecies)) {
        groupedPhotos[photo.birdSpecies] = [];
      }
      groupedPhotos[photo.birdSpecies]!.add(photo);
    }

    return Scaffold(
      backgroundColor: AppColors.surface, // Använder designsystemets bakgrundsfärg
      appBar: AppBar(
        title: const AppText.title('Mitt Fågelgalleri'),
        backgroundColor: AppColors.surface,
        scrolledUnderElevation: 0, // Förhindrar att appbaren byter färg när man scrollar
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.textPrimary))
          : groupedPhotos.isEmpty
          ? const Center(
        child: AppText.body(
          'Inga bilder ännu.\nKlicka på + för att lägga till!',
          textAlign: TextAlign.center,
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: groupedPhotos.keys.length,
        separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          String species = groupedPhotos.keys.elementAt(index);
          List<BirdPhoto> photosForSpecies = groupedPhotos[species]!;

          // Extrahera URL:er för CollectionCard
          List<String> urls = photosForSpecies.map((p) => p.imageUrl).toList();

          return CollectionCard(
            title: species,
            imagePaths: urls,
            imageUrls: urls,
            onViewPressed: () {
              // Navigera in i mappen!
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => FolderDetailsScreen(
                    folderName: species,
                    photos: photosForSpecies,
                    onRefreshRequired: _fetchPhotos,
                  ),
                ),
              );
            },
          );
        },
      ),
      // Ersatt standard-FABs med dina egna CameraIconButtons
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CameraIconButton(
            icon: Icons.camera_alt_outlined,
            onPressed: _takePicture,
            backgroundColor: AppColors.brandSecondaryDark,
            iconColor: Colors.white,
            borderColor: AppColors.brandSecondaryDark,
          ),
          const SizedBox(height: AppSpacing.md),
          CameraIconButton(
            icon: Icons.photo_library_outlined,
            onPressed: _pickImageFromGallery,
            backgroundColor: AppColors.brandSecondaryDark,
            iconColor: Colors.white,
            borderColor: AppColors.brandSecondaryDark,
          ),
        ],
      ),
    );
  }
}