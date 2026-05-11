import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:frontend/design_system/atoms/camera_shutter_button.dart';

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
  bool isTakingPicture = false; //om bild håller på att tas just nu

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
      if (!mounted) { //korrigerade varningen return i i finally
        setState(() {
          isTakingPicture = false;
        });
      }

      setState(() {
        isTakingPicture = false;
      });
    }
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
      body: Stack(
        children: [
          // första lagret (kamera livefeed)
          Positioned.fill(
            child: CameraPreview(controller),
          ),

          // andra lagret: knappar ovanpå kamera livefeed
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Text(
                  "Tryck för att identifiera fågel",
                  style: TextStyle(
                    color: Colors.white,
                    shadows: [Shadow(blurRadius: 10)],
                  ),
                ),

                const SizedBox(height: 20),

                // Ta bildknappen
                CameraShutterButton( //vår kära kameraknapp atom <3
                onPressed: _takePicture,
                isEnabled: !isTakingPicture,
                outerColor: Colors.transparent,
                innerColor: Colors.white,
                borderColor: Colors.white,
              ),
             ],
           ),
        ),
              Positioned(
              top: 50,
              right: 25,
              child: IconButton(
                icon: const Icon(
                Icons.close,
                color: Colors.white,
                size: 35,
                ),
              onPressed: () => Navigator.pop(context),
              ),
             ),
           ],
          ),
        );
    }
}