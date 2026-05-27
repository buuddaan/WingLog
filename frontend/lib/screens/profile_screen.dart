import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // <-- NY: Importera http
import 'dart:convert';
import '../core/theme/app_colors.dart';
import '../core/theme/app_gradients.dart';
import '../core/theme/app_spacing.dart';
import '../core/resources/api_config.dart'; // <-- NY: För baseUrl
import '../design_system/atoms/danger_button.dart';
import '../design_system/atoms/neutral_button.dart';
import '../design_system/molecules/delete_confirmation_dialog.dart'; // <-- NY: Dialogen
import '../services/token_service.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const ProfileScreen({super.key, required this.onLogout});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _username = 'Laddar...';
  bool _isLoading = false; // <-- NY: Håller koll på om vi laddar/raderar

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final token = await TokenService.getToken();

    if (token != null) {
      try {
        final parts = token.split('.');
        if (parts.length >= 2) {
          final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
          final payloadMap = jsonDecode(payload);

          setState(() {
            _username = payloadMap['sub'] ?? payloadMap['username'] ?? 'Okänd användare';
          });
        }
      } catch (e) {
        setState(() => _username = 'Kunde inte läsa inloggningsinfo');
      }
    }
  }

  // --- NY: Visar varningsdialogen ---
  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => DeleteConfirmationDialog(
        title: 'Radera konto?',
        description: 'Är du helt säker på att du vill radera ditt konto? Alla dina bilder, identifieringar och mappar kommer att försvinna permanent. Detta går inte att ångra.',
        confirmText: 'Ja, radera',
        cancelText: 'Avbryt',
        onConfirmPressed: () {
          Navigator.pop(ctx); // Stäng dialogen
          _deleteAccount();   // Starta borttagningen
        },
        onCancelPressed: () {
          Navigator.pop(ctx); // Stäng bara dialogen
        },
      ),
    );
  }

  // --- NY: Själva anropet mot backend ---
  Future<void> _deleteAccount() async {
    setState(() => _isLoading = true);

    try {
      final token = await TokenService.getToken();

      // OBS: Kolla din UserController i Spring Boot!
      // Jag antar här att din endpoint heter "/users/me" eller liknande.
      final url = Uri.parse('${ApiConfig.baseUrl}/users/me');

      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Kontot raderat i backend! Logga ut ur appen.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ditt konto och all data har raderats.')),
        );
        Navigator.pop(context); // Stäng profilsidan
        widget.onLogout();      // Triggar utloggning i main.dart
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kunde inte radera kontot. (Felkod: ${response.statusCode})')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nätverksfel. Kunde inte nå servern.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppGradients.loginBackground,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_circle, size: 100, color: AppColors.textPrimary),
            const SizedBox(height: 16),
            Text(
              'Inloggad som:',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              _username,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),

            const SizedBox(height: 60),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                NeutralButton.medium(
                  text: 'Logga ut',
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onLogout(); // Loggar ut lokalt
                  },
                ),
              ],
            ),

            // --- NY: Radera-knappen! ---
            const SizedBox(height: AppSpacing.xl),
            DangerButton.medium(
              text: 'Radera konto',
              onPressed: _showDeleteConfirmation,
            ),
          ],
        ),
      ),
    );
  }
}