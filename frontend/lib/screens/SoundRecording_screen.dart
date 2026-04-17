import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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

    Future.delayed(const Duration(seconds: 3), (){
        Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RecognitionResultScreen(),
            ),
        ) ;
    } );
  }

  @override
  void dispose() {
    _controller.dispose();
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
            const Text(
              'Lyssnar',
              style: TextStyle(
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

class RecognitionResultScreen extends StatelessWidget {
  const RecognitionResultScreen({super.key});

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


              const SizedBox(height: 20),
              const Text(
                'Här ska fågeldata från databasen visas senare.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}