import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:camera_macos/camera_macos.dart';

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const CameraScreen({super.key, required this.cameras});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? mobileController;
  CameraMacOSController? macOsController;
  bool isInitializing = true;

  @override
  void initState() {
    super.initState();

    if (Platform.isMacOS) {
      // För Mac behöver vi inte göra något här. CameraMacOSView sköter
      // uppstarten och sätter isInitializing till false via sin egen callback.
    } else {
      // För iOS och Android
      if (widget.cameras.isEmpty) {
        debugPrint("Inga kameror hittades (Körs du i en simulator?).");
        // Avbryt laddsnurran så skärmen inte fastnar
        setState(() { isInitializing = false; });
        return;
      }

      mobileController = CameraController(widget.cameras[0], ResolutionPreset.max, enableAudio: false);
      mobileController!.initialize().then((_) {
        if (!mounted) return;
        setState(() { isInitializing = false; });
      }).catchError((e) {
        debugPrint("Kamerafel: $e");
        setState(() { isInitializing = false; });
      });
    }
  }

  @override
  void dispose() {
    mobileController?.dispose();
    macOsController?.destroy();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isMacOS) {
      return _buildMacOsCamera();
    } else {
      return _buildMobileCamera();
    }
  }

  // --- MAC UI ---
  Widget _buildMacOsCamera() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: CameraMacOSView(
              fit: BoxFit.cover,
              cameraMode: CameraMacOSMode.photo,
              enableAudio: false,
              onCameraInizialized: (CameraMacOSController controller) {
                setState(() {
                  macOsController = controller;
                  isInitializing = false;
                });
              },
            ),
          ),
          if (isInitializing) const Center(child: CircularProgressIndicator(color: Colors.white)),
          if (!isInitializing) _buildOverlay(isMac: true),
        ],
      ),
    );
  }

  // --- MOBIL UI ---
  Widget _buildMobileCamera() {
    // Om kontrollern är null betyder det att vi är på en iOS/Android-simulator utan kamera
    if (mobileController == null) {
      return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
              children: [
                const Center(
                    child: Text("Kameran stöds inte i simulatorn.", style: TextStyle(color: Colors.white))
                ),
                _buildOverlay(isMac: false), // Ritar kryss-knappen så du kan komma därifrån!
              ]
          )
      );
    }

    if (!mobileController!.value.isInitialized) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: Colors.white,)));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: CameraPreview(mobileController!)),
          _buildOverlay(isMac: false),
        ],
      ),
    );
  }

  // --- DELAT UI FÖR KNAPPARNA ---
  Widget _buildOverlay({required bool isMac}) {
    return Stack(
      children: [
        Positioned(
          bottom: 40, left: 0, right: 0,
          child: Column(
            children: [
              const Text("Tryck för att identifiera fågel", style: TextStyle(color: Colors.white, shadows: [Shadow(blurRadius: 10)])),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () async {
                  try {
                    if (isMac) {
                      final CameraMacOSFile? image = await macOsController?.takePicture();
                      debugPrint("Mac-bild tagen! Bytes: ${image?.bytes?.length}");
                    } else {
                      final XFile? image = await mobileController?.takePicture();
                      debugPrint("Mobil-bild tagen: ${image?.path}");
                    }
                  } catch (e) {
                    debugPrint('Fel: $e');
                  }
                },
                child: Container(
                  height: 85, width: 85,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 5)),
                  child: Container(margin: const EdgeInsets.all(5), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 50, right: 25,
          child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 35), onPressed: () => Navigator.pop(context)),
        ),
      ],
    );
  }
}