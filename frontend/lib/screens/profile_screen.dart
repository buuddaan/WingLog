import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/token_service.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const ProfileScreen({super.key, required this.onLogout});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _username = 'Laddar...';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final token = await TokenService.getToken();

    if (token != null) {
      try {
        // En JWT-token består av 3 delar separerade med punkt (Header.Payload.Signature).
        // Vi vill läsa Payload (del 2) där din data ligger.
        final parts = token.split('.');
        if (parts.length >= 2) {
          final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
          final payloadMap = jsonDecode(payload);

          setState(() {
            // Kolla efter ditt användarnamn i token. Beroende på hur din Spring Boot backend
            // genererar token heter fältet oftast 'sub', 'username', eller 'email'.
            _username = payloadMap['sub'] ?? payloadMap['username'] ?? 'Okänd användare';
          });
        }
      } catch (e) {
        setState(() => _username = 'Kunde inte läsa inloggningsinfo');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: AppBar(
        title: const Text('Min Profil'),
        backgroundColor: const Color(0xFF2D5A27),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_circle, size: 100, color: Color(0xFF2D5A27)),
            const SizedBox(height: 16),
            Text(
              'Inloggad som:',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              _username, // Här visas mailen eller namnet!
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D5A27)),
            ),

            const SizedBox(height: 60),

            // Vi har flyttat utloggningsknappen hit från menyn!
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context); // Stäng profilsidan
                widget.onLogout();      // Trigga utloggning i main.dart
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Logga ut', style: TextStyle(color: Colors.red, fontSize: 18)),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red, width: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)
              ),
            ),
          ],
        ),
      ),
    );
  }
}