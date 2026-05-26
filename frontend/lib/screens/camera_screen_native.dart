import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../core/resources/api_config.dart';
import '../design_system/molecules/camera_bottom_controls.dart';
import '../design_system/molecules/camera_flow_bottom_bar.dart';
import '../design_system/molecules/selection_action_row.dart';
import '../design_system/molecules/loading_overlay.dart';
import '../services/token_service.dart';

// RAM-vänlig SessionImage för mobilen (inga bytes!)
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

  // MULTI-SELECT är tillbaka från webbversionen!
  Set<int> selectedIndices = {};

  bool isLoading = false;
  bool isViewingImage = false;
  final String sessionId = const Uuid().v4();

  final String _baseUrl = ApiConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    if (widget.cameras.isEmpty) {
      debugPrint("Inga kameror hittades.");
      return;
    }
    _initCamera(widget.cameras.first);
  }

  Future<void> _initCamera(CameraDescription cameraInfo) async {
    controller = CameraController(
      cameraInfo,
      ResolutionPreset.high, // Bäst för mobil
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

  // --- KAMERAKONTROLLER ---
  void _switchCamera() async {
    if (widget.cameras.length < 2) return;
    final currentDirection = controller.description.lensDirection;
    final newCamera = widget.cameras.firstWhere(
          (c) => c.lensDirection != currentDirection,
      orElse: () => widget.cameras.first,
    );

    setState(() => isCameraReady = false);
    await controller.dispose();
    _initCamera(newCamera);
  }

  Future<void> _toggleFlash() async {
    if (!isCameraReady) return;
    try {
      setState(() => isFlashOn = !isFlashOn);
      await controller.setFlashMode(isFlashOn ? FlashMode.always : FlashMode.off);
    } catch (e) {
      debugPrint("Kunde inte ändra blixt: $e");
    }
  }

  // --- SELEKTION ---
  void _toggleSelection(int index) {
    setState(() {
      if (selectedIndices.contains(index)) {
        selectedIndices.remove(index);
        if (selectedIndices.isEmpty) {
          isViewingImage = false;
        }
      } else {
        selectedIndices.add(index);
        isViewingImage = true;
      }
    });
  }

  // --- NÄTVERK & API ---
  Future<void> _takePicture() async {
    if (!isCameraReady || isTakingPicture) return;

    setState(() => isTakingPicture = true);

    try {
      final image = await controller.takePicture();
      final imageId = await _uploadImage(image);

      if (!mounted) return;

      if (imageId != null) {
        setState(() {
          sessionImages.add(SessionImage(file: image, imageId: imageId));
          selectedIndices.clear();
          isViewingImage = false;
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

      // KÖR DIREKT FRÅN PATH (Sparar RAM!)
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

  Future<void> _deleteSelectedImages() async {
    try {
      final token = await TokenService.getToken();

      for (int index in selectedIndices) {
        final imageId = sessionImages[index].imageId;
        await http.delete(
          Uri.parse('$_baseUrl/photos/delete-image?imageId=$imageId'),
          headers: {'Authorization': 'Bearer $token'},
        );
      }

      setState(() {
        final sortedIndices = selectedIndices.toList()..sort((a, b) => b.compareTo(a));
        for (int index in sortedIndices) {
          sessionImages.removeAt(index);
        }
        selectedIndices.clear();
        isViewingImage = false;
      });
    } catch (exception) {
      debugPrint('Fel vid radering av bild: $exception');
    }
  }

  Future<void> _identifyBird() async {
    if (selectedIndices.isEmpty) return;

    setState(() => isLoading = true);
    try {
      final token = await TokenService.getToken();

      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/photos/identify'));
      request.headers['Authorization'] = 'Bearer $token';

      // Lägger till alla markerade bilder via deras fil-paths
      for (int index in selectedIndices) {
        final image = sessionImages[index].file;
        request.files.add(await http.MultipartFile.fromPath('file', image.path));
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List;
        await _showIdentifyResultDialog(candidates);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kunde inte identifiera fågeln, försök med en annan bild')),
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
        // Återgår till live-kameran (Web-beteendet)
        setState(() {
          sessionImages.clear();
          selectedIndices.clear();
          isViewingImage = false;
        });
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
        // Återgår till live-kameran (Web-beteendet)
        setState(() {
          sessionImages.clear();
          selectedIndices.clear();
          isViewingImage = false;
        });
      }
    } catch (exception) {
      debugPrint('Fel uppstod när bilder skulle sparas: $exception');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _onCancel() async {
    if (sessionImages.isEmpty) {
      setState(() {
        selectedIndices.clear();
        isViewingImage = false;
      });
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
      if (mounted) {
        // Nollställer appen (Web-beteendet)
        setState(() {
          sessionImages.clear();
          selectedIndices.clear();
          isViewingImage = false;
        });
      }
    }
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

  @override
  Widget build(BuildContext context) {
    if (!isCameraReady) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: LoadingOverlay(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. BAKGRUND: Kameran
          Positioned.fill(
            child: CameraPreview(controller),
          ),

          // 1B. VALD BILD OVANPÅ: Ritas ut ovanpå kameran om en bild är klickad
          if (isViewingImage && selectedIndices.isNotEmpty)
            Positioned.fill(
              child: Image.file(
                File(sessionImages[selectedIndices.last].file.path),
                fit: BoxFit.cover,
              ),
            ),

          // 2. TOPP: Lista med tumnaglar
          if (sessionImages.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 12,
              right: 12,
              child: SizedBox(
                height: 72,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: sessionImages.length,
                  itemBuilder: (context, index) {
                    final isSelected = selectedIndices.contains(index);
                    return GestureDetector(
                      onTap: () => _toggleSelection(index),
                      onLongPress: () => _toggleSelection(index),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected ? Colors.blue : Colors.transparent,
                            width: isSelected ? 3 : 0,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
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

          // 3. MELLAN: De flygande knapparna för radering/tillbaka (multi-select)
          if (isViewingImage && selectedIndices.isNotEmpty)
            Positioned(
              bottom: 120,
              left: 16,
              right: 16,
              child: SelectionActionRow(
                onBack: () => setState(() {
                  isViewingImage = false;
                  selectedIndices.clear();
                }),
                onDelete: _deleteSelectedImages,
                selectedCount: selectedIndices.length,
              ),
            ),

          // 4. BOTTENMENY
          Positioned(
            left: 16,
            right: 16,
            bottom: 40,
            child: selectedIndices.isEmpty
                ? CameraBottomControls(
              onGalleryPressed: _toggleFlash,
              onShutterPressed: _takePicture,
              onSwitchCameraPressed: _switchCamera,
              isCaptureEnabled: !isTakingPicture,
              isLeftActive: isFlashOn,
            )
                : CameraFlowBottomBar(
              onCancel: _onCancel,
              onIdentify: _identifyBird,
              onSave: _saveImage,
              isIdentifyEnabled: selectedIndices.isNotEmpty,
            ),
          ),

          // 5. LADDNING
          if (isLoading) const LoadingOverlay(),
        ],
      ),
    );
  }
}