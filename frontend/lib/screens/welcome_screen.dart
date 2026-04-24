import 'package:flutter/material.dart';
// import 'package:google_sign_in/google_sign_in.dart'; EF TEST
import 'package:web/web.dart' as web; // EF TEST
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home_screen.dart';

class WelcomeScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess; // Denna tar emot _handleLoginSuccess från main
  const WelcomeScreen({super.key, required this.onLoginSuccess});


  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}


class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isLogin = true; // Växlar mellan Login och Register
  final _formKey = GlobalKey<FormState>();

  // Controllers för att hämta text från fälten
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();

  // URL till din API Gateway (justera porten om den skiljer sig)
  // Ändra denna rad byte mellan olika OS
  final String _baseUrl = 'http://localhost:8080/gateway/auth';

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final endpoint = _isLogin ? '/login' : '/register';
    final url = Uri.parse('$_baseUrl$endpoint');

    // Skapa bodyn baserat på om det är login eller register
    final Map<String, String> body = {
      'username': _usernameController.text,
      'password': _passwordController.text,
    };
    if (!_isLogin) body['email'] = _emailController.text;

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;

        // Visar det lilla bekräftelse-meddelandet
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_isLogin ? 'Välkommen tillbaka!' : 'Konto skapat!'))
        );

        // HÄR ÄR MAGIN: Navigera vidare till huvudappen!
        widget.onLoginSuccess();

      } else {
        throw Exception('Fel vid anslutning');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kunde inte nå WingLog-servern')),
      );
    }
  }
  /*
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );
// Kolla med backend om de aktiveras direkt där och
// endast behöver starta process samt hämta token istället.
// Kolla token i shared, kolla i auth-service/config/google-auth-handler

   Future<void> _handleGoogleSignIn() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return; // Användaren avbröt

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken; // Detta är den token vi skickar till backend

      final response = await http.post(
        Uri.parse('$_baseUrl/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );

      if (response.statusCode == 200) {
        widget.onLoginSuccess();
      } else {
        throw Exception('Google-inloggning misslyckades i backend');
      }
    } catch (error) {
      print(error);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kunde inte logga in med Google')),
      );
    }
  }
*/ //EF TEST

  // Test för att se om inlogg funkar mot backend flödet /EF
  void _handleGoogleSignIn() {
    web.window.location.href = 'http://localhost:8081/oauth2/authorization/google';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC), // Din Beige
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

                // Användarnamn
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'Användarnamn', border: OutlineInputBorder()),
                  validator: (value) => value!.isEmpty ? 'Ange användarnamn' : null,
                ),
                const SizedBox(height: 16),

                // Email vid registrering
                if (!_isLogin) ...[
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                    validator: (value) => value!.isEmpty ? 'Ange email' : null,
                  ),
                  const SizedBox(height: 16),
                ],

                // Lösenord
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Lösenord', border: OutlineInputBorder()),
                  validator: (value) => value!.length < 6 ? 'Minst 6 tecken' : null,
                ),
                const SizedBox(height: 24),

                // Logga in eller reg
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D5A27)),
                    child: Text(_isLogin ? 'Logga in' : 'Registrera', style: const TextStyle(color: Colors.white)),
                  ),
                ),

                // Växla mellan login/register
                TextButton(
                  onPressed: () => setState(() => _isLogin = !_isLogin),
                  child: Text(_isLogin ? 'Inget konto? Skapa ett här' : 'Har du redan ett konto? Logga in'),
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                // TEMPORÄR DEV-KNAPP: Skippa inloggning
                TextButton.icon(
                  onPressed: () {
                    // Vi struntar i backend och tvingar appen att tro att vi loggat in
                    widget.onLoginSuccess();
                  },
                  icon: const Icon(Icons.fast_forward, color: Colors.grey),
                  label: const Text(
                    'TILLFÄLLIGT: Skippa inloggning',
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