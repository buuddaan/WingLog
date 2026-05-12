import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:frontend/design_system/molecules/camera_bottom_controls.dart';
import 'package:frontend/core/theme/app_spacing.dart';

class CameraScreen extends StatefulWidget {
  //variabel som lagrar alla olika kameror (Fram, bak, vid)
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
  bool isCameraReady = false; // om kameran är färdigstartad eller ej
  bool isTakingPicture = false;//om bild håller på att tas just nu
  bool isFlashOn = false;

  @override
  void initState(){
    super.initState();
    if (widget.cameras.isEmpty) {
      debugPrint("Inga kameror hittades.");
      return;
    }
    //Startar controllern och väljer den första kameran i listan.
    controller = CameraController(
      widget.cameras[0],
      ResolutionPreset.max,
      enableAudio: false,
    );

    //Startar kameran på riktigt (hårdvaran går igång)
    controller.initialize().then((_){
      if (!mounted) return; //avbryter om användaren lämnar sidan innan kameran hinner starta
      setState(() {
        isCameraReady = true;
      }); //detta ändrar UI när kameran är redo
    }).catchError((Object e){
      debugPrint("Kamerafel: $e"); // detta loggar om något går fel
    });
  }

  @override
  void dispose(){
    if (isCameraReady) { //
      controller.dispose();
    }  //stänger ner kamera när man lämnar sidan
    super.dispose();
  }

  Future<void> _takePicture() async { // ta inte bild om kameran ej är redo/bild redan håller på att tas
    // förklara
    if (!isCameraReady || isTakingPicture) return;

    setState(() {
      isTakingPicture = true;
    });

    try {
      final image = await controller.takePicture(); //här tas bilden
      debugPrint('Bild sparad på: ${image
          .path}'); // här kan vi skicka bilden till backend senare
    } catch (e) {
      debugPrint('$e');
    } finally {
      if (mounted) { //korrigerade varningen return i i finally
        setState(() {
          isTakingPicture = false;
        });
      }
    }
  }

  void _toggleFlash () {
    setState(() {
      isFlashOn = !isFlashOn;
    });
  }

  void _retakePicture() {
    debugPrint('Ta om bild');
  }

  @override
  Widget build(BuildContext context){
    //en laddningsruta visas medans kameran laddar
    if (!isCameraReady){
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
          // första lagret (kamera live feed)
          Positioned.fill(
            child: CameraPreview(controller),
          ),

          // andra lagret: knappar ovanpå kamera live feed
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              icon: const Icon(
                Icons.close,
                color: Colors.white,
                size: 32,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
           Positioned(
            left: 0,
            right: 0,
            bottom: 40,  //position för camera controls
            child: Column(
              children: [
                const Text(
                  "Tryck för att identifiera fågel",
                  style: TextStyle(
                    color: Colors.white,
                    shadows: [Shadow(blurRadius: 10)],
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Ta bildknappen
                CameraBottomControls(
                  isLeftActive: isFlashOn,
                  onGalleryPressed: _toggleFlash,
                  onShutterPressed: _takePicture,
                  onSwitchCameraPressed: _retakePicture,
                  isCaptureEnabled: !isTakingPicture,
                ),
              ],
           ),
          ),
         ],
        ),
      ),
    );
  }
}