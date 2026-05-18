
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:frontend/design_system/molecules/camera_bottom_controls.dart';
// import 'package:frontend/core/theme/app_spacing.dart';
import 'package:frontend/design_system/molecules/camera_flow_bottom_bar.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/services/token_service.dart';
import 'package:uuid/uuid.dart';
import 'dart:typed_data';

class SessionImage {
  final XFile file;
  final String imageId;
  final Uint8List? bytes;

  SessionImage ({required this.file, required this.imageId, this.bytes});
}

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

  List<SessionImage> sessionImages = [];
  int? selectedImageIndex;
  bool isLoading = false;
  bool isViewingImage = false;
  final String sessionId = const Uuid().v4();
  final String _baseUrl = 'http://localhost:8080/gateway';

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

  ///Tar bild med kameran och laddar upp till backend. bilden läggs till i [sessionImages].
  Future<void> _takePicture() async { // ta inte bild om kameran ej är redo/bild redan håller på att tas
    if (!isCameraReady || isTakingPicture) return;

    setState(() {
      isTakingPicture = true;
    });

    try {
      final image = await controller.takePicture(); //här tas bilden
      final imageId = await _uploadImage(image);

      if(!mounted) return;

      if(imageId != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          sessionImages.add(SessionImage(file: image, imageId: imageId, bytes: bytes));
          selectedImageIndex = null;
        });
      }

      //    .path}'); // här kan vi skicka bilden till backend senare
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

  ///Laddar upp en bild till backend via API Gatewayen.
  ///Skickar bild som multipartfile tillsammans med sessionId och datum
  ///returnerar bildens id från backend om uppladdning lyckas annars null.
  Future<String?> _uploadImage(XFile image) async {
    try {
      final token = await TokenService.getToken();
      final now = DateTime.now().toIso8601String();

      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/photos/upload'),);
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['sessionId'] = sessionId;
      request.fields['date'] = now;

      final bytes = await image.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes('file', bytes,  filename: image.name));

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if(response.statusCode == 200 || response.statusCode == 201){
        final data = jsonDecode(response.body);
        return data['id'] as String;
      }
      return null;
    } catch (exception) {
      debugPrint('Fel vid uppladdning: $exception');
      return null;
    }
  }

  void _toggleFlash () {
    setState(() {
      isFlashOn = !isFlashOn;
    });
  }

  ///Hanterar avbrytning av kamerasessionen.
  ///Ombilder tagits visas en dialog där användaren kan välja att radera alla.
  ///om ja anropas _deleteSession.
  Future<void> _onCancel() async {
    if (sessionImages.isEmpty){
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
            child: const Text('Radera')
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await _deleteSession();
    }

    if(mounted) Navigator.pop(context);
  }

  ///Radarear alla bilder som tillhör en session
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

  ///Raderar en enskild bild från backend och tar bort denna från sessionImages.
  ///Återgår till kameraläge efter radering
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

  ///Identifierar fågelartern på den markerade bilden via Google Vision API.
  ///Kräver en tumbnail markerad via selectedImageIndex
  ///visar identifieringsresultat i en dialog där användaren kan namnge en mapp
  Future<void> _identifyBird() async {
    if (selectedImageIndex == null) return;

    setState(() => isLoading = true);
    try {
      final token = await TokenService.getToken();
      final image = sessionImages[selectedImageIndex!].file;

      var request = http.MultipartRequest(
        'POST', Uri.parse('$_baseUrl/photos/identify'),
      );
      request.headers['Authorization'] = 'Bearer $token';

      final bytes = await image.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(
        'file', bytes, filename: image.name,)
      );

      final steamed = await request.send();
      final response = await http.Response.fromStream(steamed);

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
      if (mounted) setState (() => isLoading = false);
    }
  }

  ///Visar en dialog med identifieringsresultat från Google Vision API.
  /// Listar topp 5 fågelarter som är möjliga med sannolikhet i procent.
  Future<void> _showIdentifyResultDialog(List candidates) async {
    final folderController = TextEditingController();

    if(candidates.isNotEmpty) {
      folderController.text =candidates.first['species'] ?? '';
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title:const Text('Identifieringsresultat'),
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
            const Text('Namnge mappen;'),
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
            onPressed:  () => Navigator.pop(ctx),
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

  /// Sparar alla bilder i sessionen i en namnvigen mapp
  /// Stänger kameran efter att bilerna sparats
  Future<void> _saveToFolder(String folderName) async {
    try {
      final token = await TokenService.getToken();
      await http.put(
        Uri.parse('$_baseUrl/photos/save-to-folder?sessionId=$sessionId&folderName=${Uri.encodeComponent(folderName)}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sparad i mappen "$folderName"')),
        );
        Navigator.pop(context);
      }
    } catch (exception) {
      debugPrint('Fel vid sparning: $exception');
    }

  }

  ///Sparar alla bilder i sessionen som oidentifierade i backend.
  ///Stänger kameran efter att bilder sparats.
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Bilder sparade som oidentifierade')),
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
          Positioned.fill(
            child: isViewingImage && selectedImageIndex != null && sessionImages[selectedImageIndex!].bytes != null ? Image.memory(
              sessionImages[selectedImageIndex!].bytes!, fit: BoxFit.cover,
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
                          child: sessionImages[index].bytes != null
                              ? Image.memory(
                                  sessionImages[index].bytes!,
                                  width: 60,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(Icons.image, color: Colors.white),
                          ),
                        ),
                    );
                  },
                ),
              ),
            ),

          if (isViewingImage && selectedImageIndex != null)
            Positioned(
              bottom:40,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: () => setState (() {
                      isViewingImage = false;
                      selectedImageIndex = null;
                    }),
                    icon:const Icon(Icons.arrow_back, color: Colors.white),
                    label: const Text ('Tillbacka', style: TextStyle(color: Colors.white)),
                  ),
                  TextButton.icon(
                    onPressed: () => _deleteImage(selectedImageIndex!),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text('Radera', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
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
            left: 16,
            right: 16,
            bottom: 40,  //position för camera controls
            child: sessionImages.isEmpty ? CameraBottomControls(
                onGalleryPressed: _toggleFlash,
                onShutterPressed: _takePicture,
                onSwitchCameraPressed: null,
                isCaptureEnabled:  !isTakingPicture,
                isLeftActive: isFlashOn,
            )
             : CameraFlowBottomBar(
                onCancel: _onCancel,
                onIdentify: _identifyBird,
                onSave: _saveImage,
                isIdentifyEnabled: selectedImageIndex != null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}