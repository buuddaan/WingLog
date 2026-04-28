import 'dart:io';
import 'dart:convert';
//import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;

class SoundRecordingScreen extends StatelessWidget{
    const SoundRecordingScreen ({super.key});

    @override
    Widget build (BuildContext context) {
        return Scaffold(
            body: Center(
                child: GestureDetector(
                    onTap: (){
                        Navigator.push(
                            context,
                           MaterialPageRoute(
                               builder: (context) => const ListeningScreen(),
                           ),
                        );
                    },
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 20,
                        ),
                     decoration: BoxDecoration(
                        border: Border.all(
                            color: Colors.green,
                            width: 5,
                        ),
                        borderRadius: BorderRadius.circular(40),
                    ),
                    child: Text('Spela in ljud'),
                ),
              ),
            ),
         );
} }

   class ListeningScreen extends StatefulWidget {
  const ListeningScreen({super.key});

  @override
  State<ListeningScreen> createState() => _ListeningScreenState();
}

class _ListeningScreenState extends State<ListeningScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  final AudioRecorder _audioRecorder = AudioRecorder();
  String _status = 'Startar inspelning...';


  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _startRecordingFlow();
  }

  Future<void> _startRecordingFlow() async {
    await _startRecording();

    await Future.delayed(const Duration(seconds: 5));

    final path = await _stopRecording();

    if (!mounted) return;

    Map<String, dynamic>? birdResult;

    if (path != null) {
      try {
        final uri = Uri.parse('http://localhost:8087/audio/identify');
        final request = http.MultipartRequest('POST', uri);

        if (kIsWeb) {
          final response = await http.get(Uri.parse(path));
          request.files.add(http.MultipartFile.fromBytes(
            'file',
            response.bodyBytes,
            filename: 'recording.m4a',
          ));
        } else {
          request.files.add(await http.MultipartFile.fromPath('file', path));
        }

        final streamedResponse = await request.send();
        final responseBody = await streamedResponse.stream.bytesToString();
        birdResult = jsonDecode(responseBody);
      } catch (e) {
        debugPrint('Fel vid anrop till backend: $e');
      }
    }

    if (!mounted) return;

    final navigator = Navigator.of(context);

    navigator.pushReplacement(
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
      final hasPermission = await _audioRecorder.hasPermission();

      if (!hasPermission) {
        setState(() {
          _status = 'Mikrofonbehörighet nekad';
        });
        return;
      }

      late final String filePath;

      if (kIsWeb) {
        filePath = 'bird_sound_${DateTime.now().millisecondsSinceEpoch}.m4a';
      } else {
        final Directory appDir = await getApplicationDocumentsDirectory();
        filePath =
        '${appDir.path}/bird_sound_${DateTime.now().millisecondsSinceEpoch}.m4a';
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
  void dispose() {
    _controller.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spela in'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _status,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ScaleTransition(
              scale: _scaleAnimation,
              child: const Icon(
                Icons.mic,
                size: 90,
                color: Color(0xFF2D5A27),
              ),
            ),
          ],
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
      appBar: AppBar(
        title: const Text('Resultat'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
              if (widget.birdResult != null) ...[
                Text(
                  widget.birdResult!['birdName'] ?? 'Okänd',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.birdResult!['scientificName'] ?? '',
                  style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '${((widget.birdResult!['confidence'] as num) * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
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
              const SizedBox (height: 20),
              ElevatedButton(
                onPressed: _isPlaying ? _stopPlayback : _playRecording,
                child: Text(_isPlaying ? 'Stoppa ljud' : 'Spela upp ljud'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}