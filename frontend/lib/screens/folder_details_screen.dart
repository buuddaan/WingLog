import 'package:flutter/material.dart';
import 'package:frontend/screens/single_image_screen.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

import '../core/resources/api_config.dart';
import 'gallery_screen.dart'; // För BirdPhoto-modellen
import '../services/token_service.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../design_system/atoms/app_text.dart';
import '../design_system/atoms/camera_icon_button.dart';

class FolderDetailsScreen extends StatefulWidget {
  final String folderName;
  final List<BirdPhoto> photos;
  final VoidCallback onRefreshRequired;

  const FolderDetailsScreen({
    super.key,
    required this.folderName,
    required this.photos,
    required this.onRefreshRequired,
  });

  @override
  State<FolderDetailsScreen> createState() => _FolderDetailsScreenState();
}

class _FolderDetailsScreenState extends State<FolderDetailsScreen> {
  late String _currentFolderName;
  late List<BirdPhoto> _currentPhotos;

  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
// I gallery_screen.dart och folder_details_screen.dart
  final String _baseUrl = '${ApiConfig.baseUrl}/photos';
  @override
  void initState() {
    super.initState();
    _currentFolderName = widget.folderName;
    _currentPhotos = List.from(widget.photos);
  }

  // --- HÄMTA UPPDATERAD MAPP ---
  // Körs efter en ny bild har laddats upp för att uppdatera rutnätet
  Future<void> _refreshFolder() async {
    try {
      final token = await TokenService.getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/my-photos'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final allPhotos = data.map((json) => BirdPhoto.fromJson(json)).toList();

        setState(() {
          // Filtrera fram endast bilderna för den nuvarande mappen
          _currentPhotos = allPhotos.where((p) => p.birdSpecies == _currentFolderName).toList();
        });
        widget.onRefreshRequired(); // Säg till huvudgalleriet att det finns nya bilder
      }
    } catch (e) {
      debugPrint("Fel vid uppdatering av mapp: $e");
    }
  }

  // --- LADDA UPP NY BILD TILL DENNA MAPP ---
  Future<void> _pickAndUploadToFolder() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile == null || !mounted) return;

    setState(() => _isLoading = true);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Laddar upp bild...')));

    try {
      final token = await TokenService.getToken();
      final String sessionId = const Uuid().v4();
      final String currentDate = DateTime.now().toIso8601String();

      var uploadRequest = http.MultipartRequest('POST', Uri.parse('$_baseUrl/upload'));
      uploadRequest.headers['Authorization'] = 'Bearer $token';
      uploadRequest.fields['sessionId'] = sessionId;
      uploadRequest.fields['date'] = currentDate;

      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        uploadRequest.files.add(http.MultipartFile.fromBytes('file', bytes, filename: pickedFile.name));
      } else {
        uploadRequest.files.add(await http.MultipartFile.fromPath('file', pickedFile.path));
      }

      var streamedResponse = await uploadRequest.send();

      if (streamedResponse.statusCode == 200 || streamedResponse.statusCode == 201) {
        // Hoppar över dialogen - vi vet ju redan namnet! (_currentFolderName)
        final saveResponse = await http.put(
          Uri.parse('$_baseUrl/save-to-folder?sessionId=$sessionId&folderName=${Uri.encodeComponent(_currentFolderName)}'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (saveResponse.statusCode == 200) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bild tillagd i mappen!')));
          await _refreshFolder(); // Uppdatera bilderna på skärmen
        } else {
          throw Exception('Serverfel vid namngivning.');
        }
      } else {
        throw Exception('Uppladdning misslyckades.');
      }
    } catch (e) {
      debugPrint("Fel vid uppladdning: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fel: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- BEFINTLIGA FUNKTIONER FÖR RADERA/BYT NAMN ---
  Future<void> _renameFolder(String newName) async {
    try {
      final token = await TokenService.getToken();
      final response = await http.put(
        Uri.parse('$_baseUrl/rename-folder?oldName=${Uri.encodeComponent(_currentFolderName)}&newName=${Uri.encodeComponent(newName)}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() => _currentFolderName = newName);
        widget.onRefreshRequired();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mappen har döpts om!')));
      }
    } catch (e) {
      debugPrint('Fel vid namnbyte: $e');
    }
  }

  Future<void> _deleteImage(String imageId, int index) async {
    try {
      final token = await TokenService.getToken();
      final response = await http.delete(
        Uri.parse('$_baseUrl/delete-image?imageId=$imageId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() => _currentPhotos.removeAt(index));
        widget.onRefreshRequired();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bilden har raderats.')));
        if (_currentPhotos.isEmpty && mounted) Navigator.of(context).pop();
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kunde inte radera bilden. Felkod: ${response.statusCode}')));
      }
    } catch (e) {
      debugPrint('Fel vid radering av bild: $e');
    }
  }

  Future<void> _deleteFolder() async {
    try {
      final token = await TokenService.getToken();
      final response = await http.delete(
        Uri.parse('$_baseUrl/delete-folder?folderName=${Uri.encodeComponent(_currentFolderName)}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        widget.onRefreshRequired();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mappen har raderats.')));
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      debugPrint('Fel vid radering av mapp: $e');
    }
  }

  // --- DIALOGER ---
  void _showRenameDialog() {
    String newName = _currentFolderName;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const AppText.title('Ändra namn på mappen'),
        content: TextField(
          controller: TextEditingController(text: _currentFolderName),
          onChanged: (value) => newName = value,
          decoration: const InputDecoration(hintText: "Nytt mappnamn"),
        ),
        actions: [
          TextButton(
            child: const AppText.label('Avbryt'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const AppText.label('Spara', color: AppColors.brandSecondaryDark),
            onPressed: () {
              Navigator.pop(context);
              if (newName.isNotEmpty && newName != _currentFolderName) _renameFolder(newName);
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteFolderConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: AppText.title('Radera "$_currentFolderName"?'),
        content: const AppText.body('Detta tar bort mappen och ALLA bilder i den. Går inte att ångra.'),
        actions: [
          TextButton(
            child: const AppText.label('Avbryt'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const AppText.label('Radera', color: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _deleteFolder();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: AppText.title(_currentFolderName),
        backgroundColor: AppColors.surface,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.textPrimary),
            onPressed: _showRenameDialog,
            tooltip: 'Byt namn',
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
            onPressed: _showDeleteFolderConfirmation,
            tooltip: 'Radera mapp',
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.textPrimary))
          : Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: GridView.builder(
          itemCount: _currentPhotos.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
          ),
          itemBuilder: (context, index) {
            final photo = _currentPhotos[index];
            return Stack(
              children: [

                // --- ÄNDRING HÄR: Gör bilden klickbar ---
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),

                    // Omslut bilden med GestureDetector för att lyssna på klick
                    child: GestureDetector(
                      onTap: () {
                        // Navigera till fullskärmsvyn!
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => SingleImageScreen(
                              imageUrl: photo.imageUrl,
                              birdSpecies: _currentFolderName, // Skicka med namnet om vi vill visa det
                            ),
                          ),
                        );
                      },

                      // Själva bilden
                      child: Image.network(
                        photo.imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(child: CircularProgressIndicator(color: AppColors.textPrimary));
                        },
                      ),
                    ),
                  ),
                ),
                // ------------------------------------------

                // Din befintliga raderings-knapp (lilla krysset)
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => _deleteImage(photo.id, index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                      child: const Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            );
          },
        ), // <-- DENNA SAKNADES (Stänger GridView.builder)
      ),   // <-- DENNA SAKNADES (Stänger Padding)

      // LÄGG TILL KNAPPEN HÄR! (Tillhör Scaffold)
      floatingActionButton: CameraIconButton(
        icon: Icons.add_photo_alternate_outlined,
        onPressed: _pickAndUploadToFolder,
        backgroundColor: AppColors.brandSecondaryDark,
        iconColor: Colors.white,
        borderColor: AppColors.brandSecondaryDark,
      ),
    );
  }
}