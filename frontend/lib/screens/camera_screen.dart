import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraScreen extends StatefulWidget {
  //variabel som lagrar alla olika kareror (Fram, bak, vid)
  final List<CameraDescription> cameras;
  const CameraScreen({super.key, required this.cameras});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>{
  late CameraController controller;

  @override
  void initState(){
    super.initState();
    //Startar controllern och väljer den första kameran i listan.
    controller = CameraController(
      widget.cameras[0],
      ResolutionPreset.max,
      enableAudio: false,
    );

    //Startar kameran på riktigt (hårdvaran går igång)
    controller.initialize().then((_){
      if (!mounted) return; //avbryter om användaren lämnar sidan innan kameran hinner starta
      setState(() {}); //detta ändrar UI när kameran är redo
    }).catchError((Object e){
      print("Kamerafel: $e"); // detta loggar om något går fel
    });
  }

  @override
  void dispose(){
    controller.dispose(); //stänger ner kamera när man lämnar sidan
    super.dispose();
  }

  @override
  Widget build(BuildContext context){
    //en laddningsruta visas medans kameran laddar
    if (!controller.value.isInitialized){
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // första lagret (kamera livefeed)
          Positioned.fill(child: CameraPreview(controller),),

          // andra lagret: knappar ovanpå kamera livefeed
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Text(
                  "Tryck för att identifiera fågel",
                  style: TextStyle(color: Colors.white, shadows: [Shadow(blurRadius: 10)]),
                ),
                const SizedBox(height: 20),

                // Ta bildknappen
                GestureDetector(
                  onTap: () async{
                    try {
                      final image = await controller.takePicture();
                      print("Bild sparad på: ${image.path}");
                      // här kan vi skicka bilden till backend
                    } catch (e) {
                      print (e);
                    }
                  },
                  child: Container(
                    height: 85,
                    width: 85,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 5),
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // det tredje lagret: knapp för att kunna kryssa ut
          Positioned(
            top: 50,
            right: 25,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 35),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}