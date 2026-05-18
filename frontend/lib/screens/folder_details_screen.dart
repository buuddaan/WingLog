import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'gallery_screen.dart'; // För att komma åt BirdPhoto-modellen
import '../services/token_service.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../design_system/atoms/app_text.dart';

class FolderDetailsScreen extends StatefulWidget {
  final String folderName;
  final List<BirdPhoto> photos;
  final VoidCallback onRefreshRequired; // Callback för att uppdatera huvudgalleriet när vi går tillbaka

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
  final String _baseUrl = 'http://localhost:8080/gateway/photos';

  @override
  void initState() {
    super.initState();
    _currentFolderName = widget.folderName;
    _currentPhotos = List.from(widget.photos);
  }

  // --- API ANROP ---

  // 1. Byt namn på mappen
  Future<void> _renameFolder(String newName) async {
    try {
      final token = await TokenService.getToken();
      final response = await http.put(
        Uri.parse('$_baseUrl/rename-folder?oldName=${Uri.encodeComponent(_currentFolderName)}&newName=${Uri.encodeComponent(newName)}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _currentFolderName = newName;
        });
        widget.onRefreshRequired();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mappen har döpts om!')));
        }
      }
    } catch (e) {
      debugPrint('Fel vid namnbyte: $e');
    }
  }

  // 2. Ta bort en enskild bild
  Future<void> _deleteImage(String imageId, int index) async {
    try {
      final token = await TokenService.getToken();
      final response = await http.delete(
        Uri.parse('$_baseUrl/delete-image?imageId=$imageId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() {
          _currentPhotos.removeAt(index);
        });
        widget.onRefreshRequired();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bilden har raderats.')));
        }
        // Om mappen blev helt tom, gå automatiskt tillbaka till galleriet
        if (_currentPhotos.isEmpty && mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      debugPrint('Fel vid radering av bild: $e');
    }
  }

  // 3. Ta bort en hel mapp (och alla dess bilder)
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
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mappen och alla dess bilder har raderats.')));
          Navigator.of(context).pop(); // Gå tillbaka till huvudgalleriet
        }
      }
    } catch (e) {
      debugPrint('Fel vid radering av mapp: $e');
    }
  }

  // --- DIALOGRUTOR ---

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
              if (newName.isNotEmpty && newName != _currentFolderName) {
                _renameFolder(newName);
              }
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
        title: AppText.title('Radera mappen "$_currentFolderName"?'),
        content: const AppText.body('Detta kommer att ta bort mappen och ALLA bilder i den permanent. Detta går inte att ångra.'),
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
          // Knapp för att ändra namn
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.textPrimary),
            onPressed: _showRenameDialog,
            tooltip: 'Byt namn på mappen',
          ),
          // Knapp för att radera hela mappen
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
            onPressed: _showDeleteFolderConfirmation,
            tooltip: 'Radera hela mappen',
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: GridView.builder(
          itemCount: _currentPhotos.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // 3 bilder i bredd
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
          ),
          itemBuilder: (context, index) {
            final photo = _currentPhotos[index];

            return Stack(
              children: [
                // Själva bilden
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      photo.imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Liten raderingsknapp överst till höger på bilden
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => _deleteImage(photo.id, index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}