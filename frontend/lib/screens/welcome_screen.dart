import 'package:flutter/material.dart'; // DENNA RAD SAKNAS

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF5F5DC),
      body: Center(
        child: Text(
          'Välkommen till WingLog\n\nVälj en funktion nedan för att börja.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: Color(0xFF2D5A27)),
        ),
      ),
    );
  }
}