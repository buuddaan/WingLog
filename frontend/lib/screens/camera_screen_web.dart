import 'dart:convert';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../core/resources/api_config.dart';
import '../design_system/atoms/media_thumb.dart';
import '../design_system/molecules/camera_bottom_controls.dart';
import '../design_system/molecules/camera_flow_bottom_bar.dart';
import '../design_system/molecules/delete_confirmation_dialog.dart';
import '../design_system/molecules/loading_overlay.dart';
import '../services/token_service.dart';

class SessionImage {
  final XFile file;
  final String imageId;
  final Uint8List? bytes;

  SessionImage({
    required this.file,
    required this.imageId,
    this.bytes,
  });
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
  // bool isFlashOn = false;
  bool isLoading = false;
  bool isViewingImage = false;
  bool isSwitchingCamera = false;


  int currentCameraIndex = 0;

  List<SessionImage> sessionImages = [];
  Set<int> selectedIndices = {};

  final String sessionId = const Uuid().v4();
  final String _baseUrl = ApiConfig.baseUrl;

  @override
  void initState() {
    super.initState();

    if (widget.cameras.isEmpty) {
      debugPrint('Inga kameror hittades.');
      return;
    }

    _initializeCamera(widget.cameras[currentCameraIndex]);
  }


  Future<void> _initializeCamera(CameraDescription camera) async {
    controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await controller.initialize();

      if (!mounted) return;

      setState(() {
        isCameraReady = true;
      });
    } catch (e) {
      debugPrint('Kamerafel: $e');
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

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

 // void _toggleFlash() {
  //  setState(() {
    //  isFlashOn = !isFlashOn; });}

  Future<void> _switchCamera() async {
    if (widget.cameras.length < 2 || isSwitchingCamera) return;

    isSwitchingCamera = true;

    try {
      final newIndex = (currentCameraIndex + 1) % widget.cameras.length;

      setState(() {
        isCameraReady = false;
      });

      await controller.dispose();

      controller = CameraController(
        widget.cameras[newIndex],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize();

      if (!mounted) return;

      setState(() {
        currentCameraIndex = newIndex;
        isCameraReady = true;
      });
    } catch (e) {
      debugPrint('Fel vid byte av kamera: $e');

      if (!mounted) return;

      setState(() {
        isCameraReady = true;
      });
    } finally {
      isSwitchingCamera = false;
    }
  }

  Future<void> _takePicture() async {
    if (!isCameraReady || isTakingPicture) return;

    setState(() {
      isTakingPicture = true;
    });

    try {
      final image = await controller.takePicture();
      final imageId = await _uploadImage(image);

      if (!mounted) return;

      if (imageId != null) {
        final bytes = await image.readAsBytes();

        setState(() {
          sessionImages.add(
            SessionImage(
              file: image,
              imageId: imageId,
              bytes: bytes,
            ),
          );

          selectedIndices.clear();
          isViewingImage = false; // för att kunna fortsätta ta flera bilder
        });
      }
    } catch (e) {
      debugPrint('Fel vid fotografering: $e');
    } finally {
      if (mounted) {
        setState(() {
          isTakingPicture = false;
        });
      }
    }
  }

  Future<String?> _uploadImage(XFile image) async {
    try {
      final token = await TokenService.getToken();
      final now = DateTime.now().toIso8601String();

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/photos/upload'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['sessionId'] = sessionId;
      request.fields['date'] = now;

      final bytes = await image.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: image.name,
        ),
      );

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

  Future<void> _saveImage() async {
    if (sessionImages.isEmpty) return; // ändrade från selectedIndices.isEmpty

    setState(() => isLoading = true);

    try {
      final token = await TokenService.getToken();

      await http.put(
        Uri.parse('$_baseUrl/photos/save-unidentified?sessionId=$sessionId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bilder sparade som oidentifierade'),
        ),
      );

      setState(() {
        sessionImages.clear();
        selectedIndices.clear();
        isViewingImage = false;
      });
    } catch (exception) {
      debugPrint('Fel uppstod när bilder skulle sparas: $exception');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _showCancelSessionDialog() async {
    if (sessionImages.isEmpty) return;

    await showDialog( //metod för ta bort session på ta bild state
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Avbryt session?'),
        content: const Text(
          'Vill du avbryta sessionen? Alla osparade bilder försvinner.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Nej'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();

              setState(() {
                sessionImages.clear();
                selectedIndices.clear();
                isViewingImage = false;
              });
            },
            child: const Text('Avbryt session'),
          ),
        ],
      ),
    );
  }


  Future<void> _showDeleteDialog() async {  //pop upp radera bild fråga
    if (selectedIndices.isEmpty) return;

    await showDialog(
      context: context,
      builder: (context) => DeleteConfirmationDialog(
        title: 'Radera bild?',
        description: 'Vill du ta bort denna bild?',
        onCancelPressed: () => Navigator.of(context).pop(),
        onConfirmPressed: () {
          Navigator.of(context).pop();
          _deleteSelectedImages();
        },
      ),
    );
  }

  Future<void> _deleteSelectedImages() async {
    try {
      final token = await TokenService.getToken();

      for (final index in selectedIndices) {
        final imageId = sessionImages[index].imageId;

        await http.delete(
          Uri.parse('$_baseUrl/photos/delete-image?imageId=$imageId'),
          headers: {'Authorization': 'Bearer $token'},
        );
      }

      setState(() {
        final sortedIndices = selectedIndices.toList()
          ..sort((a, b) => b.compareTo(a));

        for (final index in sortedIndices) {
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

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/photos/identify'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      for (final index in selectedIndices) {
        final image = sessionImages[index].file;
        final bytes = sessionImages[index].bytes;

        if (bytes != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'file',
              bytes,
              filename: image.name,
            ),
          );
        }
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
          const SnackBar(
            content: Text('Kunde inte identifiera fågeln, försök med en annan bild'),
          ),
        );
      }
    } catch (exception) {
      debugPrint('Fel vid identifiering: $exception');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
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
            const Text(
              'Möjliga arter:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...candidates.take(5).map((c) {
              final percent =
              ((c['confidence'] as double) * 100).toStringAsFixed(0);
              return Text('${c['species']} - $percent%');
            }),
            const SizedBox(height: 16),
            const Text('Namnge mappen'),
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
        Uri.parse(
          '$_baseUrl/photos/save-to-folder?sessionId=$sessionId&folderName=${Uri.encodeComponent(folderName)}',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sparad i mappen "$folderName"')),
        );

        setState(() {
          sessionImages.clear();
          selectedIndices.clear();
          isViewingImage = false;
        });
      }
    } catch (exception) {
      debugPrint('Fel vid sparande: $exception');
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
          Positioned.fill(
            child: CameraPreview(controller),
          ),

          if (isViewingImage &&
              selectedIndices.isNotEmpty &&
              sessionImages[selectedIndices.last].bytes != null)
            Positioned.fill(
              child: Image.memory(
                sessionImages[selectedIndices.last].bytes!,
                fit: BoxFit.cover,
              ),
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
                    return GestureDetector(
                      onTap: () => _toggleSelection(index),
                      onLongPress: () => _toggleSelection(index),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: MediaThumb.memory(
                          imageBytes: sessionImages[index].bytes!,
                          isSelected: selectedIndices.contains(index),
                          size: MediaThumbSize.medium,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 40,
            child: !isViewingImage
                ? CameraBottomControls(
              onCancelSessionPressed: sessionImages.isNotEmpty ? _showCancelSessionDialog : null,
              onShutterPressed: _takePicture,
              onSwitchCameraPressed: _switchCamera,
              onSaveSessionPressed: sessionImages.isNotEmpty ? _saveImage : null, //eventuellt skapa showSaveDialog
              isCaptureEnabled: !isTakingPicture,
              isSessionActionEnabled: sessionImages.isNotEmpty,
            )
                : CameraFlowBottomBar(
              onBack: () => setState(() {
                isViewingImage = false;
                selectedIndices.clear();
              }),
              onSave: selectedIndices.isNotEmpty ? _saveImage : null,
              onIdentify:
              selectedIndices.isNotEmpty ? _identifyBird : null,
              onDelete:
              selectedIndices.isNotEmpty ? _showDeleteDialog : null,
              isSaveEnabled: selectedIndices.isNotEmpty,
              isIdentifyEnabled: selectedIndices.isNotEmpty,
              isDeleteEnabled: selectedIndices.isNotEmpty,
            ),
          ),

          if (isLoading) const LoadingOverlay(),
        ],
      ),
    );
  }
}