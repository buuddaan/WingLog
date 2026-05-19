import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart'; // Lade till url_launcher!
import '../core/resources/api_config.dart';
import '../services/token_service.dart';
import 'package:frontend/design_system/organisms/login_background.dart';
import 'package:frontend/design_system/organisms/login_form.dart';

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

  // --- HÄR ÄR DEN NYA GOOGLE-INLOGGNINGEN ---
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
      body: Stack(
        children: [
          const LoginBackground(),
          Positioned(
            top: 90,
            left: 0,
            right: 0,
            child: LoginForm(
              formKey: _formKey,
              isLogin: _isLogin,
              usernameController: _usernameController,
              emailController: _emailController,
              passwordController: _passwordController,
              onSubmit: _submitForm,
              onGoogleSignIn: _handleGoogleSignIn,
              onToggleMode: () {
                setState(() {
                  _isLogin = !_isLogin;
                  _formKey.currentState?.reset();
                  _usernameController.clear();
                  _emailController.clear();
                  _passwordController.clear();
                });
              },
              onSkipLogin: widget.onLoginSuccess,
            ),
          ),
        ],
      ),
    );
  }
}