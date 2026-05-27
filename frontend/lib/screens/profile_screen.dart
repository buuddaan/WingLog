import 'package:flutter/material.dart';
import 'dart:convert';
import '../core/theme/app_colors.dart';
import '../core/theme/app_gradients.dart';
import '../design_system/atoms/neutral_button.dart';
import '../services/token_service.dart';
import '../design_system/atoms/danger_button.dart';

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
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Min Profil'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        flexibleSpace:Container(
          decoration:  BoxDecoration(
            gradient: AppGradients.loginBackground, //ändrat header där det står min profil
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_circle, size: 100, color : AppColors.textPrimary),
            const SizedBox(height: 16),
            Text(
              'Inloggad som:',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              _username, // Här visas mail eller namnet!
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color : AppColors.textPrimary),
            ),

            const SizedBox(height: 60),

            // Vi har flyttat utloggningsknappen hit från menyn!
            IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NeutralButton.medium(
                  text: 'Logga ut',
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onLogout();
                  },
                ),
                const SizedBox(height: 12),
                DangerButton.medium(
                  text: 'Radera konto',
                  onPressed: () {
                    // TODO: Lägg in delete account flow här
                  },
                ),
              ],
            ),
            ),
          ],
        ),
      ),
    );
  }
}