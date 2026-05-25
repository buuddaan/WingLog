import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:frontend/design_system/molecules/camera_bottom_controls.dart';
import 'package:frontend/design_system/molecules/camera_flow_bottom_bar.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/services/token_service.dart';
import 'package:uuid/uuid.dart';
import 'dart:typed_data';

import '../core/resources/api_config.dart';
//import '../design_system/atoms/app_close_button.dart';
import '../design_system/atoms/media_thumb.dart';
import '../design_system/molecules/loading_overlay.dart';
import '../design_system/molecules/selection_action_row.dart';

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

  // NYTT: Set istället för int för multi-select!
  Set<int> selectedIndices = {};

  bool isLoading = false;
  bool isViewingImage = false;
  final String sessionId = const Uuid().v4();

  // I gallery_screen.dart och folder_details_screen.dart
  final String _baseUrl = ApiConfig.baseUrl;

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
      ResolutionPreset.high,
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

  // NYTT: Funktion för att välja / välja bort flera bilder
  void _toggleSelection(int index) {
    setState(() {
      if (selectedIndices.contains(index)) {
        selectedIndices.remove(index); // Avmarkera om den redan är vald
        if (selectedIndices.isEmpty) {
          isViewingImage = false; // Gå tillbaka till kamera om inget är valt
        }
      } else {
        selectedIndices.add(index); // Markera
        isViewingImage = true; // Visa bilden stort
      }
    });
  }

  ///Tar bild med kameran och laddar upp till backend. bilden läggs till i [sessionImages].
  Future<void> _takePicture() async {
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
          // NYTT: Avmarkera bilder om vi tar ett nytt foto
          selectedIndices.clear();
          isViewingImage = false;
        });
      }
    } catch (e) {
      debugPrint('$e');
    } finally {
      if (mounted) {
        setState(() {
          isTakingPicture = false;
        });
      }
    }
  }

  ///Laddar upp en bild till backend via API Gatewayen.
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
  // NYTT: Raderar alla valda bilder
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

  ///Identifierar fågelartern på de markerade bilderna via Google Vision API.
  Future<void> _identifyBird() async {
    if (selectedIndices.isEmpty) return;

    setState(() => isLoading = true);
    try {
      final token = await TokenService.getToken();

      var request = http.MultipartRequest(
        'POST', Uri.parse('$_baseUrl/photos/identify'),
      );
      request.headers['Authorization'] = 'Bearer $token';

      // NYTT: Loopar igenom valda index och lägger till alla filer (som bytes för web)
      for (int index in selectedIndices) {
        final image = sessionImages[index].file;
        final bytes = sessionImages[index].bytes;

        if (bytes != null) {
          request.files.add(http.MultipartFile.fromBytes(
            'file', bytes, filename: image.name,
          ));
        }
      }

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
        // FIXAT: Återgår till live-kameran istället för att stänga skärmen
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Bilder sparade som oidentifierade')),
        );
        // FIXAT: Återgår till live-kameran istället för att stänga skärmen
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
    if (sessionImages.isEmpty){
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
        // FIXAT: Nollställer appen och visar live-kameran istället för att hoppa ur
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
  Widget build(BuildContext context){
    if (!isCameraReady){
      return const Scaffold(
        backgroundColor: Colors.black,
        body: LoadingOverlay(), // Din nya molekyl!
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. BAKGRUND (LIVE-KAMERA): Ligger ALLTID i botten och fryser aldrig
          Positioned.fill(
            child: CameraPreview(controller),
          ),

          // 1B. VALD BILD OVANPÅ: Ritas ut ovanpå kameran om en bild är klickad
          if (isViewingImage && selectedIndices.isNotEmpty && sessionImages[selectedIndices.last].bytes != null)
            Positioned.fill(
              child: Image.memory(
                sessionImages[selectedIndices.last].bytes!,
                fit: BoxFit.cover,
              ),
            ),

          // 2. TOPP: Lista med tumnaglar (alltid synlig när vi har tagit bilder)
          if (sessionImages.isNotEmpty)
            Positioned(
              top: 12, left: 12, right: 12,
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

          // 3. MELLAN: De flygande knapparna (syns BARA när vi tittar på en bild)
          if (isViewingImage && selectedIndices.isNotEmpty)
            Positioned(
              bottom: 120, left: 16, right: 16,
              child: SelectionActionRow(
                onBack: () => setState (() {
                  isViewingImage = false;
                  selectedIndices.clear(); // Går tillbaka till kameran, som snurrar live bakom!
                }),
                onDelete: _deleteSelectedImages,
                selectedCount: selectedIndices.length,
              ),
            ),

          // 4. BOTTENMENY
          Positioned(
            left: 16, right: 16, bottom: 40,
            child: selectedIndices.isEmpty
                ? CameraBottomControls(
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
              isIdentifyEnabled: selectedIndices.isNotEmpty,
            ),
          ),

          // 5. LADDNING
          if (isLoading) const LoadingOverlay(),
        ],
      ),
    ); // <-- HÄR var felet! En extra parentes är nu borttagen.
  }
}