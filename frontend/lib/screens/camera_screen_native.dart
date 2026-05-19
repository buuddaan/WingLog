import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io'; // NYTT: Behövs för att hantera filer på iOS/Android
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../core/resources/api_config.dart';
import '../design_system/molecules/camera_bottom_controls.dart';
import '../design_system/molecules/camera_flow_bottom_bar.dart';
import '../services/token_service.dart';

// Vi tog bort 'bytes' härifrån för att spara RAM-minne på mobilen.
class SessionImage {
  final XFile file;
  final String imageId;

  SessionImage({required this.file, required this.imageId});
}

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraScreen({
    super.key,
    required this.cameras,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController controller;
  bool isCameraReady = false;
  bool isTakingPicture = false;
  bool isFlashOn = false;

  List<SessionImage> sessionImages = [];
  int? selectedImageIndex;
  bool isLoading = false;
  bool isViewingImage = false;
  final String sessionId = const Uuid().v4();

  // VIKTIGT FÖR MOBIL: Byt ut 192.168.X.X mot din dators riktiga IP-adress!
  // localhost fungerar inte på en iPhone eftersom telefonen är en egen enhet.
// I gallery_screen.dart och folder_details_screen.dart
  final String _baseUrl = ApiConfig.baseUrl;
  @override
  void initState() {
    super.initState();
    if (widget.cameras.isEmpty) {
      debugPrint("Inga kameror hittades.");
      return;
    }
    // Startar med den första kameran (oftast baksidan)
    _initCamera(widget.cameras.first);
  }

  // Egen metod för att starta kameran så vi kan återanvända den när vi byter kamera
  Future<void> _initCamera(CameraDescription cameraInfo) async {
    controller = CameraController(
      cameraInfo,
      ResolutionPreset.max, // Ger bäst bildkvalitet på mobilen
      enableAudio: false,
    );

    try {
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        isCameraReady = true;
      });
    } catch (e) {
      debugPrint("Kamerafel: $e");
    }
  }

  @override
  void dispose() {
    if (isCameraReady) {
      controller.dispose();
    }
    super.dispose();
  }

  // --- NYTT: Vänd kamera (Fram / Bak) ---
  void _switchCamera() async {
    if (widget.cameras.length < 2) return; // Gör inget om vi bara har 1 kamera

    // Hitta vilken riktning kameran har nu, och välj den andra
    final currentDirection = controller.description.lensDirection;
    final newCamera = widget.cameras.firstWhere(
          (c) => c.lensDirection != currentDirection,
      orElse: () => widget.cameras.first,
    );

    setState(() => isCameraReady = false);
    await controller.dispose();
    _initCamera(newCamera);
  }

  // --- NYTT: Riktig blixt-kontroll ---
  Future<void> _toggleFlash() async {
    if (!isCameraReady) return;
    try {
      setState(() => isFlashOn = !isFlashOn);
      // Säger till hårdvaran att tända/släcka lampan vid kort
      await controller.setFlashMode(isFlashOn ? FlashMode.always : FlashMode.off);
    } catch (e) {
      debugPrint("Kunde inte ändra blixt: $e");
    }
  }

  Future<void> _takePicture() async {
    if (!isCameraReady || isTakingPicture) return;

    setState(() => isTakingPicture = true);

    try {
      final image = await controller.takePicture();
      final imageId = await _uploadImage(image);

      if (!mounted) return;

      if (imageId != null) {
        setState(() {
          // Vi sparar inte bytes! Bara filen och ID:t.
          sessionImages.add(SessionImage(file: image, imageId: imageId));
          selectedImageIndex = null;
        });
      }
    } catch (e) {
      debugPrint('Fel vid fotografering: $e');
    } finally {
      if (mounted) setState(() => isTakingPicture = false);
    }
  }

  Future<String?> _uploadImage(XFile image) async {
    try {
      final token = await TokenService.getToken();
      final now = DateTime.now().toIso8601String();

      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/photos/upload'));
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['sessionId'] = sessionId;
      request.fields['date'] = now;

      // --- NYTT FÖR MOBIL: Vi laddar upp filen direkt via dess path! ---
      // Detta är otroligt mycket mer minneseffektivt än fromBytes på en iPhone.
      request.files.add(await http.MultipartFile.fromPath('file', image.path));

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['id'] as String;
      }
      return null;
    } catch (exception) {
      debugPrint('Fel vid uppladdning: $exception');
      return null;
    }
  }

  Future<void> _onCancel() async {
    if (sessionImages.isEmpty) {
      Navigator.pop(context);
      return;
    }
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Avbryt Session'),
        content: const Text('Vill du radera alla bilder från denna session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Behåll'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Radera', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await _deleteSession();
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _deleteSession() async {
    try {
      final token = await TokenService.getToken();
      await http.delete(
        Uri.parse('$_baseUrl/photos/delete-session?sessionId=$sessionId'),
        headers: {'Authorization': 'Bearer $token'},
      );
    } catch (exception) {
      debugPrint('Fel vid radering av session: $exception');
    }
  }

  Future<void> _deleteImage(int index) async {
    try {
      final token = await TokenService.getToken();
      final imageId = sessionImages[index].imageId;

      await http.delete(
        Uri.parse('$_baseUrl/photos/delete-image?imageId=$imageId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      setState(() {
        sessionImages.removeAt(index);
        selectedImageIndex = null;
        isViewingImage = false;
      });
    } catch (exception) {
      debugPrint('Fel vid radering av bild: $exception');
    }
  }

  Future<void> _identifyBird() async {
    if (selectedImageIndex == null) return;

    setState(() => isLoading = true);
    try {
      final token = await TokenService.getToken();
      final image = sessionImages[selectedImageIndex!].file;

      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/photos/identify'));
      request.headers['Authorization'] = 'Bearer $token';

      // Även här använder vi fromPath
      request.files.add(await http.MultipartFile.fromPath('file', image.path));

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List;
        await _showIdentifyResultDialog(candidates);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kunde inte identifiera fågeln.')),
        );
      }
    } catch (exception) {
      debugPrint('Fel vid identifiering: $exception');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _showIdentifyResultDialog(List candidates) async {
    final folderController = TextEditingController();

    if (candidates.isNotEmpty) {
      folderController.text = candidates.first['species'] ?? '';
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Identifieringsresultat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Möjliga arter:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...candidates.take(5).map((c) {
              final percent = ((c['confidence'] as double) * 100).toStringAsFixed(0);
              return Text('${c['species']} - $percent%');
            }),
            const SizedBox(height: 16),
            const Text('Namnge mappen:'),
            const SizedBox(height: 8),
            TextField(
              controller: folderController,
              decoration: const InputDecoration(
                hintText: 'T.ex. Blåmes',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Avbryt'),
          ),
          TextButton(
            onPressed: () async {
              final folderName = folderController.text.trim();
              if (folderName.isEmpty) return;
              Navigator.pop(ctx);
              await _saveToFolder(folderName);
            },
            child: const Text('Spara i mapp'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveToFolder(String folderName) async {
    try {
      final token = await TokenService.getToken();
      await http.put(
        Uri.parse('$_baseUrl/photos/save-to-folder?sessionId=$sessionId&folderName=${Uri.encodeComponent(folderName)}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sparad i mappen "$folderName"')),
        );
        Navigator.pop(context);
      }
    } catch (exception) {
      debugPrint('Fel vid sparning: $exception');
    }
  }

  Future<void> _saveImage() async {
    if (sessionImages.isEmpty) return;

    setState(() => isLoading = true);

    try {
      final token = await TokenService.getToken();
      await http.put(
        Uri.parse('$_baseUrl/photos/save-unidentified?sessionId=$sessionId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bilder sparade som oidentifierade')),
        );
        Navigator.pop(context);
      }
    } catch (exception) {
      debugPrint('Fel uppstod när bilder skulle sparas: $exception');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isCameraReady) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: isViewingImage && selectedImageIndex != null
              // --- NYTT FÖR MOBIL: Image.file istället för Image.memory ---
                  ? Image.file(
                File(sessionImages[selectedImageIndex!].file.path),
                fit: BoxFit.cover,
              )
                  : CameraPreview(controller),
            ),

            if (sessionImages.isNotEmpty)
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: SizedBox(
                  height: 72,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: sessionImages.length,
                    itemBuilder: (context, index) {
                      final isSelected = selectedImageIndex == index;
                      return GestureDetector(
                        onTap: () => setState(() {
                          selectedImageIndex = index;
                          isViewingImage = true;
                        }),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected ? Colors.blue : Colors.white,
                              width: isSelected ? 3 : 1.5,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            // --- NYTT FÖR MOBIL: Image.file för thumbnails ---
                            child: Image.file(
                              File(sessionImages[index].file.path),
                              width: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

            if (isViewingImage && selectedImageIndex != null)
              Positioned(
                bottom: 120, // Flyttade upp lite så den inte krockar med bottom baren
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      onPressed: () => setState(() {
                        isViewingImage = false;
                        selectedImageIndex = null;
                      }),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      label: const Text('Tillbaka', style: TextStyle(color: Colors.white)),
                    ),
                    TextButton.icon(
                      onPressed: () => _deleteImage(selectedImageIndex!),
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text('Radera', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ),

            // Stängkryss
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // Bottenmeny (Kameraknappar eller spar-flöde)
            Positioned(
              left: 16,
              right: 16,
              bottom: 40,
              child: sessionImages.isEmpty
                  ? CameraBottomControls(
                onGalleryPressed: _toggleFlash, // Knapp för blixt
                onShutterPressed: _takePicture, // Ta bild
                onSwitchCameraPressed: _switchCamera, // Vänd kamera
                isCaptureEnabled: !isTakingPicture,
                isLeftActive: isFlashOn,
              )
                  : CameraFlowBottomBar(
                onCancel: _onCancel,
                onIdentify: _identifyBird,
                onSave: _saveImage,
                isIdentifyEnabled: selectedImageIndex != null,
              ),
            ),

            // Visar laddningshjul vid AI-identifiering
            if (isLoading)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}