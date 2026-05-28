import 'dart:io';
import 'dart:convert';
import 'package:frontend/core/theme/app_spacing.dart';
import 'package:frontend/design_system/molecules/animated_mic_button.dart';
import 'package:frontend/design_system/molecules/section_header.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/design_system/atoms/app_gradient_background.dart';

// --- NYA IMPORTER ---
import 'package:permission_handler/permission_handler.dart';
import '../design_system/molecules/permission_denied_view.dart';
import '../design_system/molecules/loading_overlay.dart';

import '../core/resources/api_config.dart';
import '../services/token_service.dart';

class SoundRecordingScreen extends StatelessWidget {
  const SoundRecordingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppGradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: "Spela in ljud",
                  centerTitle: true,
                  trailing: IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.settings_outlined),
                  ),
                ),
                const Spacer(),
                Center(
                  child: AnimatedMicButton(
                    isListening: false,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ListeningScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 1. LÄGG TILL WidgetsBindingObserver
class ListeningScreen extends StatefulWidget {
  const ListeningScreen({super.key});

  @override
  State<ListeningScreen> createState() => _ListeningScreenState();
}

class _ListeningScreenState extends State<ListeningScreen> with WidgetsBindingObserver {
  final AudioRecorder _audioRecorder = AudioRecorder();
  String _status = 'Startar inspelning...';

  // State-variabler för behörigheter (precis som kameran)
  bool _hasPermission = false;
  bool _isCheckingPermission = true;

  @override
  void initState() {
    super.initState();
    // Börja lyssna på system-events (när man byter mellan app och inställningar)
    WidgetsBinding.instance.addObserver(this);

    // Fråga direkt vid uppstart!
    _checkPermissionAndInit();
  }

  @override
  void dispose() {
    // Sluta lyssna när vi lämnar skärmen
    WidgetsBinding.instance.removeObserver(this);
    _audioRecorder.dispose();
    super.dispose();
  }

  // 2. KÖRS AUTOMATISKT NÄR DU KOMMER TILLBAKA FRÅN INSTÄLLNINGAR
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_hasPermission) {
        _checkPermissionAndInit(); // Kolla automatiskt igen!
      }
    }
  }

  // 3. FRÅGA OCH HANTERA BEHÖRIGHET (Precis som kameran)
  Future<void> _checkPermissionAndInit() async {
    if (!mounted) return;
    setState(() => _isCheckingPermission = true);

    if (kIsWeb) {
      // Webb hanterar mikrofontillstånd via webbläsaren automatiskt
      setState(() {
        _hasPermission = true;
        _isCheckingPermission = false;
      });
      _startRecordingFlow();
      return;
    }

    // Ropa request() direkt! Tvingar fram det sanna svaret från iOS.
    final status = await Permission.microphone.request();

    if (!mounted) return;

    if (status.isGranted) {
      setState(() {
        _hasPermission = true;
        _isCheckingPermission = false;
      });
      // Behörighet godkänd - starta själva ljudinspelningen!
      _startRecordingFlow();
    } else {
      // Om blockerad, visa vår PermissionDeniedView
      setState(() {
        _hasPermission = false;
        _isCheckingPermission = false;
      });
    }
  }

  // 4. SJÄLVA INSPELNINGSFLÖDET (Körs enbart om vi har tillåtelse)
  Future<void> _startRecordingFlow() async {
    await _startRecording();

    // Spelar in i 5 sekunder
    await Future.delayed(const Duration(seconds: 5));

    final path = await _stopRecording();

    if (!mounted) return;

    Map<String, dynamic>? birdResult;

    if (path != null) {
      try {
        final token = await TokenService.getToken();
        final uri = Uri.parse('${ApiConfig.baseUrl}/audio/identify');
        final request = http.MultipartRequest('POST', uri);
        request.headers['Authorization'] = 'Bearer $token';

        if (kIsWeb) {
          final response = await http.get(Uri.parse(path));
          request.files.add(
            http.MultipartFile.fromBytes(
              'file',
              response.bodyBytes,
              filename: 'recording.m4a',
            ),
          );
        } else {
          request.files.add(
            await http.MultipartFile.fromPath('file', path),
          );
        }

        final streamedResponse = await request.send();
        final responseBody = await streamedResponse.stream.bytesToString();
        birdResult = jsonDecode(responseBody);
      } catch (e) {
        debugPrint('Fel vid anrop till backend: $e');
      }
    }

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => RecognitionResultScreen(
          recordedFilePath: path,
          birdResult: birdResult,
        ),
      ),
    );
  }

  Future<void> _startRecording() async {
    try {
      late final String filePath;

      if (kIsWeb) {
        filePath = 'bird_sound_${DateTime.now().millisecondsSinceEpoch}.m4a';
      } else {
        final Directory appDir = await getApplicationDocumentsDirectory();
        filePath = '${appDir.path}/bird_sound_${DateTime.now().millisecondsSinceEpoch}.m4a';
      }

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          numChannels: 1,
          sampleRate: 44100,
          bitRate: 128000,
        ),
        path: filePath,
      );

      setState(() {
        _status = 'Lyssnar...';
      });
    } catch (e) {
      setState(() {
        _status = 'Fel vid start: $e';
      });
    }
  }

  Future<String?> _stopRecording() async {
    try {
      return await _audioRecorder.stop();
    } catch (e) {
      setState(() {
        _status = 'Fel vid stopp: $e';
      });
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Visar laddningshjul medan vi kollar behörighet
    if (_isCheckingPermission) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: LoadingOverlay(),
      );
    }

    // 2. Visar molekylen om vi saknar behörighet
    if (!_hasPermission) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: AppGradientBackground(
          child: PermissionDeniedView(
            title: 'Mikrofon saknas',
            description: 'WingLog behöver mikrofonen för att spela in och identifiera fågelsång.',
            icon: Icons.mic_off_outlined,
            onRetry: _checkPermissionAndInit, // Tvingar en manuell om-koll om de klickar
          ),
        ),
      );
    }

    // 3. Om vi har tillåtelse, visa inspelningsanimationen
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppGradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                SectionHeader(
                  title: _status,
                  centerTitle: true,
                ),
                Expanded(
                  child: Center(
                    child: AnimatedMicButton(
                      isListening: true,
                      onTap: () {},
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RecognitionResultScreen extends StatefulWidget {
  final String? recordedFilePath;
  final Map<String, dynamic>? birdResult;

  const RecognitionResultScreen({
    super.key,
    this.recordedFilePath,
    this.birdResult,
  });

  @override
  State<RecognitionResultScreen> createState() => _RecognitionResultScreenState();
}

class _RecognitionResultScreenState extends State<RecognitionResultScreen> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  Future<void> _playRecording() async {
    if (widget.recordedFilePath == null) return;

    try {
      if (kIsWeb) {
        await _player.play(
          UrlSource(widget.recordedFilePath!),
        );
      } else {
        await _player.play(
          DeviceFileSource(widget.recordedFilePath!),
        );
      }

      setState(() {
        _isPlaying = true;
      });
    } catch (e) {
      debugPrint('Playback error: $e');
    }
  }

  Future<void> _stopPlayback() async {
    await _player.stop();

    setState(() {
      _isPlaying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppGradientBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    const SectionHeader(
                      title: 'Resultat',
                      centerTitle: true,
                    ),
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Ljudigenkänning klar',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                const Icon(
                                  Icons.flutter_dash,
                                  size: 120,
                                  color: Color(0xFF2D5A27),
                                ),
                                const SizedBox(height: 16),
                                if (widget.birdResult?['suggestions'] != null) ...[
                                  ...(widget.birdResult!['suggestions'] as List).map((s) {
                                    final pct = ((s['confidence'] as num) * 100).toStringAsFixed(1);
                                    return Card(
                                      margin: const EdgeInsets.symmetric(vertical: 6),
                                      child: ListTile(
                                        leading: const Icon(
                                          Icons.flutter_dash,
                                          color: Color(0xFF2D5A27),
                                        ),
                                        title: Text(
                                          s['birdName'] ?? 'Okänd',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Text(
                                          s['scientificName'] ?? '',
                                          style: const TextStyle(fontStyle: FontStyle.italic),
                                        ),
                                        trailing: Text(
                                          '$pct%',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ),
                                    );
                                  }),
                                ] else
                                  const Text(
                                    'Kunde inte identifiera fågeln.',
                                    textAlign: TextAlign.center,
                                  ),
                                const SizedBox(height: 20),
                                if (widget.recordedFilePath != null)
                                  Text(
                                    'Inspelad fil:\n${widget.recordedFilePath}',
                                    textAlign: TextAlign.center,
                                  ),
                                const SizedBox(height: 32),
                                ElevatedButton.icon(
                                  onPressed: _isPlaying ? _stopPlayback : _playRecording,
                                  icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                                  label: Text(_isPlaying ? 'Stoppa ljud' : 'Spela upp ljud'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: AppSpacing.sm,
                left: AppSpacing.sm,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      if (_isPlaying) _player.stop();
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}