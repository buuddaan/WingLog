import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart'; // Lade till url_launcher!
import '../core/resources/api_config.dart';
import '../services/token_service.dart';

// VI TOG BORT DE VILLKORLIGA IMPORTERNA HÄR UPPE! 🎉

class WelcomeScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  const WelcomeScreen({super.key, required this.onLoginSuccess});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isLogin = true;
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();

  final String _baseUrl = '${ApiConfig.baseUrl}/auth';
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final response = await http.post(
        _authUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(_buildAuthRequestBody()),
      );

      if (!context.mounted) return;

      await _handleAuthResponse(response);
    } catch (e) {
      if (!context.mounted) return;

      _showSnackBar(
        'Kunde inte nå WingLog-servern. Kontrollera din anslutning.',
      );
    }
  }

  Uri get _authUrl {
    final endpoint = _isLogin ? '/login' : '/register';
    return Uri.parse('$_baseUrl$endpoint');
  }

  Map<String, String> _buildAuthRequestBody() {
    final requestBody = {
      'username': _usernameController.text,
      'password': _passwordController.text,
    };

    if (!_isLogin) {
      requestBody['email'] = _emailController.text;
    }

    return requestBody;
  }

  Future<void> _handleAuthResponse(http.Response response) async {
    final statusCode = response.statusCode;
    final isSuccessfulResponse = statusCode == 200 || statusCode == 201;
    final isAuthError = statusCode == 401 || statusCode == 403;
    final isValidationOrConflictError = statusCode == 400 || statusCode == 409;

    if (isSuccessfulResponse) {
      final data = jsonDecode(response.body);
      final token = data['token'];

      await TokenService.saveToken(token);

      _showSnackBar(_isLogin ? 'Välkommen tillbaka!' : 'Konto skapat!');
      widget.onLoginSuccess();
      return;
    }

    if (isAuthError) {
      _showSnackBar('Fel användarnamn eller lösenord.');
      return;
    }

    if (isValidationOrConflictError) {
      _showSnackBar(
        _isLogin
            ? 'Inloggningen misslyckades. Kontrollera dina uppgifter.'
            : 'Användarnamnet eller e-postadressen är redan upptagen.',
      );
      return;
    }

    _showSnackBar('Något gick fel på servern. (Felkod: $statusCode)');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // --- HÄR ÄR DEN NYA GOOGLE-INLOGGNINGEN --- // Axel, denna ändras efter API config för att lösa telefon google?
  static const String _googleLoginUrl = 'http://localhost:8080/gateway/oauth2/authorization/google';

  Future<void> _handleGoogleSignIn() async {
    final Uri googleLoginUri = Uri.parse(_googleLoginUrl);

    final bool wasLaunched = await launchUrl(
      googleLoginUri,
      mode: LaunchMode.externalApplication,
    );

    if (!wasLaunched && context.mounted) {
      _showGoogleSignInLaunchError();
    }
  }

  void _showGoogleSignInLaunchError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kunde inte öppna Google-inloggningen.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.flutter_dash, size: 80, color: Color(0xFF2D5A27)),
                const SizedBox(height: 16),
                Text(
                  _isLogin ? 'Logga in på WingLog' : 'Skapa WingLog-konto',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D5A27)),
                ),
                const SizedBox(height: 32),
                OutlinedButton.icon(
                  onPressed: _handleGoogleSignIn,
                  icon: const Icon(Icons.login),
                  label: const Text('Logga in med Google'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'Användarnamn', border: OutlineInputBorder()),
                  validator: (value) => value!.isEmpty ? 'Ange användarnamn' : null,
                ),
                const SizedBox(height: 16),

                if (!_isLogin) ...[
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                    validator: (value) => value!.isEmpty ? 'Ange email' : null,
                  ),
                  const SizedBox(height: 16),
                ],

                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Lösenord', border: OutlineInputBorder()),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ange lösenord';
                    }
                    if (!_isLogin && value.length < 8) {
                      return 'Minst 8 tecken krävs';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D5A27)),
                    child: Text(_isLogin ? 'Logga in' : 'Registrera', style: const TextStyle(color: Colors.white)),
                  ),
                ),

                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin;
                      _formKey.currentState?.reset();
                    });
                  },
                  child: Text(_isLogin ? 'Inget konto? Skapa ett här' : 'Har du redan ett konto? Logga in'),
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                TextButton.icon(
                  onPressed: () {
                    widget.onLoginSuccess();
                  },
                  icon: const Icon(Icons.fast_forward, color: Colors.grey),
                  label: const Text(
                    'TILLFÄLLIGT: Skippa inloggning', //låt vara kvar
                    style: TextStyle(color: Colors.red),
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