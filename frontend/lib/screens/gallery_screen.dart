import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  // Lista för att hålla våra valda/tagna bilder temporärt
  final List<File> _imageFiles = [];

  // Instans av image_picker för att prata med telefonens galleri
  final ImagePicker _picker = ImagePicker();

  // --- FUNKTION: Hämta bild från telefonens galleri ---
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Komprimerar bilden lite för att spara minne
      );

      if (pickedFile != null) {
        setState(() {
          _imageFiles.add(File(pickedFile.path));
        });

        // TODO för framtiden:
        // Här kan du skicka bilden till din Spring Boot 'photo-service' via ett http.post-anrop!
      }
    } catch (e) {
      debugPrint("Ett fel uppstod när bilden skulle hämtas: $e");
    }
  }

  // --- FUNKTION: Hämta bild från kameran direkt (Extra) ---
  Future<void> _takePicture() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (photo != null) {
        setState(() {
          _imageFiles.add(File(photo.path));
        });
      }
    } catch (e) {
      debugPrint("Ett fel uppstod med kameran: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),

      body: _imageFiles.isEmpty
          ? const Center(
        child: Text(
          'Inga bilder ännu.\nKlicka på + för att lägga till!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: Colors.black54),
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(8.0),
        // GridView skapar ett snyggt rutnät av bilderna
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // 3 bilder per rad
            crossAxisSpacing: 8, // Mellanrum i sidled
            mainAxisSpacing: 8, // Mellanrum i höjdled
          ),
          itemCount: _imageFiles.length,
          itemBuilder: (context, index) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.file(
                _imageFiles[index],
                fit: BoxFit.cover, // Fyller rutan snyggt
              ),
            );
          },
        ),
      ),
      // Knappar nere i hörnet för att lägga till bilder
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "btn_camera", // Behövs om man har flera FABs på samma skärm
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