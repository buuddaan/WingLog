import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/resources/api_config.dart';
import '../services/token_service.dart';
import 'package:http_parser/http_parser.dart';

class SingleImageScreen extends StatefulWidget {
  final String imageUrl;
  final String birdSpecies;
  final String imageId; // <-- NYTT: Vi behöver bildens ID för att kunna flytta den på servern

  const SingleImageScreen({
    super.key,
    required this.imageUrl,
    required this.birdSpecies,
    required this.imageId,
  });

  @override
  State<SingleImageScreen> createState() => _SingleImageScreenState();
}

class _SingleImageScreenState extends State<SingleImageScreen> {
  bool _showControls = true;
  bool _isIdentifying = false; // Håller koll på laddningshjulet när AI:n tänker

  // --- 1. FUNKTION FÖR ATT IDENTIFIERA BILDEN ---
  Future<void> _identifyBird() async {
    setState(() => _isIdentifying = true);

    try {
      final token = await TokenService.getToken(); // Hämta token först!

      // --- FIXEN ÄR HÄR ---
      // Vi måste skicka med din JWT-token när vi laddar ner bilden från din server!
      final imageResponse = await http.get(
        Uri.parse(widget.imageUrl),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (imageResponse.statusCode != 200) {
        debugPrint('Nedladdning misslyckades. Status: ${imageResponse.statusCode}');
        throw Exception('Kunde inte hämta bilddata.');
      }
      // ---------------------

      // Skicka till AI-endpointen
      var request = http.MultipartRequest('POST', Uri.parse('${ApiConfig.baseUrl}/photos/identify'));
      request.headers['Authorization'] = 'Bearer $token';

      request.files.add(http.MultipartFile.fromBytes(
        'file',
        imageResponse.bodyBytes,
        filename: 'image_to_identify.jpg',
        contentType: MediaType('image', 'jpeg'),
      ));

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List;
        await _showIdentifyResultDialog(candidates);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kunde inte identifiera fågeln. Försök igen.')),
        );
      }
    } catch (e) {
      debugPrint('Fel vid identifiering: $e');
    } finally {
      if (mounted) setState(() => _isIdentifying = false);
    }
  }

  // --- 2. VISA AI-RESULTATET ---
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
            const Text('Flytta till mapp:'),
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
              await _moveToNewFolder(folderName);
            },
            child: const Text('Spara och flytta'),
          ),
        ],
      ),
    );
  }

  // --- 3. FLYTTA BILDEN PÅ SERVER ---
  Future<void> _moveToNewFolder(String folderName) async {
    setState(() => _isIdentifying = true);
    try {
      final token = await TokenService.getToken();

      // OBS: Beroende på hur din backend ser ut kan du behöva justera denna URL!
      final uri = Uri.parse('${ApiConfig.baseUrl}/photos/move-image?imageId=${widget.imageId}&newFolderName=${Uri.encodeComponent(folderName)}');

      final response = await http.put(uri, headers: {'Authorization': 'Bearer $token'});

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Bilden har flyttats till "$folderName"')),
          );
          Navigator.pop(context, true); // Skickar tillbaka "true" så mappen kan uppdateras
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Kunde inte flytta bilden. Status: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      debugPrint('Fel vid flytt av bild: $e');
    } finally {
      if (mounted) setState(() => _isIdentifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _showControls = !_showControls;
              });
            },
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              boundaryMargin: const EdgeInsets.all(20.0),
              child: Center(
                child: Image.network(
                  widget.imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator(color: AppColors.surface));
                  },
                ),
              ),
            ),
          ),

          // TILLBAKA-KNAPPEN (Vänster)
          Positioned(
            top: MediaQuery.of(context).padding.top + AppSpacing.sm,
            left: AppSpacing.sm,
            child: AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: IgnorePointer(
                ignoring: !_showControls,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ),
            ),
          ),

          // NYTT: IDENTIFIERA-KNAPPEN (Längst ner i mitten)
          Positioned(
            bottom: 48, // Avstånd från botten
            left: 0,    // Drar i vänsterkanten
            right: 0,   // Drar i högerkanten för att centrera
            child: Center(
              child: AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: IgnorePointer(
                  ignoring: !_showControls,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _identifyBird,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        // Lite generösare padding när den står fritt i botten
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(16),
                          // En liten ram (border) kan göra att den ser ännu mer ut som en riktig knapp!
                          border: Border.all(color: Colors.white24, width: 1),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.image_search,
                              color: Colors.white,
                              size: 28, // Gjorde ikonen lite större!
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Identifiera',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // LADDNINGSHJUL OM AI:N TÄNKER
          if (_isIdentifying)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}