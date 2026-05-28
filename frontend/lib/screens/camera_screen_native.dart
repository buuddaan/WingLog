import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/resources/api_config.dart';
import '../design_system/molecules/camera_bottom_controls.dart';
import '../design_system/molecules/camera_flow_bottom_bar.dart';
import '../design_system/molecules/selection_action_row.dart';
import '../design_system/molecules/loading_overlay.dart';
import '../design_system/molecules/permission_denied_view.dart';
import '../services/token_service.dart';

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

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  late CameraController controller;
  bool isCameraReady = false;
  bool isTakingPicture = false;
  bool isFlashOn = false;

  // --- ZOOM-VARIABLER ---
  double _currentZoomLevel = 1.0;
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;
  double _baseZoomLevel = 1.0; // Används för att räkna ut skillnaden när man nyper

  bool _hasPermission = false;
  bool _isCheckingPermission = true;
  String? _cameraError;

  List<CameraDescription> _localCameras = [];
  List<SessionImage> sessionImages = [];
  Set<int> selectedIndices = {};

  bool isLoading = false;
  bool isViewingImage = false;
  final String sessionId = const Uuid().v4();
  final String _baseUrl = ApiConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _localCameras = widget.cameras;
    _checkPermissionAndInit();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (isCameraReady) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_hasPermission) {
        _checkPermissionAndInit();
      }
    }
  }

  Future<void> _checkPermissionAndInit() async {
    if (!mounted) return;
    setState(() => _isCheckingPermission = true);

    final status = await Permission.camera.request();

    if (!mounted) return;

    if (status.isGranted) {
      if (_localCameras.isEmpty) {
        try {
          _localCameras = await availableCameras();
        } catch (e) {
          debugPrint("Kunde inte hämta kameror: $e");
        }
      }

      if (_localCameras.isNotEmpty) {
        setState(() {
          _hasPermission = true;
          _isCheckingPermission = false;
        });

        if (!isCameraReady) {
          _initCamera(_localCameras.first);
        }
      } else {
        setState(() {
          _hasPermission = true;
          _isCheckingPermission = false;
          _cameraError = "Ingen kamerahårdvara hittades. Kör du på en simulator?";
        });
      }
    } else {
      setState(() {
        _hasPermission = false;
        _isCheckingPermission = false;
      });
    }
  }

  Future<void> _initCamera(CameraDescription cameraInfo) async {
    controller = CameraController(
      cameraInfo,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await controller.initialize();

      // --- HÄMTA TELEFONENS MAX/MIN ZOOM ---
      _maxAvailableZoom = await controller.getMaxZoomLevel();
      _minAvailableZoom = await controller.getMinZoomLevel();
      _currentZoomLevel = _minAvailableZoom;

      if (!mounted) return;
      setState(() {
        isCameraReady = true;
        _cameraError = null;
      });
    } catch (e) {
      debugPrint("Kamerafel: $e");
      if (mounted) {
        setState(() {
          _cameraError = e.toString();
        });
      }
    }
  }

  void _switchCamera() async {
    if (_localCameras.length < 2) return;
    final currentDirection = controller.description.lensDirection;
    final newCamera = _localCameras.firstWhere(
          (c) => c.lensDirection != currentDirection,
      orElse: () => _localCameras.first,
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
      // Sätt laddningsskärm så användaren inte kan trycka på annat medan vi raderar från molnet
      setState(() => isLoading = true);

      await _deleteSession();

      if (mounted) {
        setState(() {
          sessionImages.clear();
          selectedIndices.clear();
          isViewingImage = false;
          isLoading = false; // Ta bort laddningsskärmen
        });
      }
    }
  }

  Future<void> _deleteSession() async {
    try {
      final token = await TokenService.getToken();

      // 1. Radera alla bilder individuellt för att säkerställa att Cloudinary rensas
      for (var image in sessionImages) {
        final imageId = image.imageId;
        await http.delete(
          Uri.parse('$_baseUrl/photos/delete-image?imageId=$imageId'),
          headers: {'Authorization': 'Bearer $token'},
        );
      }

      // 2. Radera själva sessionen i backend (ifall din databas håller koll på den)
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
    if (_isCheckingPermission) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: LoadingOverlay(),
      );
    }

    if (!_hasPermission) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: PermissionDeniedView(
          title: 'Kameraåtkomst saknas',
          description: 'WingLog behöver tillgång till kameran för att du ska kunna fota och identifiera fåglar.',
          icon: Icons.camera_alt_outlined,
          onRetry: _checkPermissionAndInit,
        ),
      );
    }

    if (_cameraError != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 16),
                const Text('Kameran kunde inte startas:', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(_cameraError!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
    }

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
          // --- GESTURE DETECTOR FÖR PINCH-TO-ZOOM ---
          Positioned.fill(
            child: GestureDetector(
              onScaleStart: (details) {
                // Sparar startläget för zoomen
                _baseZoomLevel = _currentZoomLevel;
              },
              onScaleUpdate: (details) async {
                if (!isCameraReady) return;

                // Räkna ut ny zoom
                double newZoom = _baseZoomLevel * details.scale;

                // Tvinga värdet att stanna inom kamerans max/min
                newZoom = newZoom.clamp(_minAvailableZoom, _maxAvailableZoom);

                if (newZoom != _currentZoomLevel) {
                  setState(() {
                    _currentZoomLevel = newZoom;
                  });
                  await controller.setZoomLevel(_currentZoomLevel);
                }
              },
              child: CameraPreview(controller),
            ),
          ),

          if (isViewingImage && selectedIndices.isNotEmpty)
            Positioned.fill(
              child: Image.file(
                File(sessionImages[selectedIndices.last].file.path),
                fit: BoxFit.cover,
              ),
            ),

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

          if (isLoading) const LoadingOverlay(),
        ],
      ),
    );
  }
}