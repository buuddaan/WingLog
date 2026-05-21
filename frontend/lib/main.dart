import 'package:flutter/material.dart';
import 'screens/main_layout.dart';
import 'screens/welcome_screen.dart';
import 'package:camera/camera.dart';
import 'services/token_service.dart';
import 'core/theme/app_theme.dart';

// Saknades för körning /EF
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'core/resources/api_config.dart';

List<CameraDescription> cameras = []; // Denna variabel ropar main_layout.dart på!

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cameras = await availableCameras();
  } catch (e) {
    debugPrint("Kunde inte starta kameran: $e");
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // 1. Variabeln som styr om vi ser Login eller Homepage
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
  }

  // Kolla först om vi kom tillbaka från Google-inloggning med engångskod
  // Annars: kolla om "kom ihåg mig" är aktivt och en sparad token finns
  void _checkExistingSession() async {
    // 1. Kom vi tillbaka från Google-inloggning med en engångskod? /EF
    final uri = Uri.base;
    final code = uri.queryParameters['code'];
    if (code != null) {
      try {
        final response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/auth/exchange'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'code': code}),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final token = data['token'] as String;
          await TokenService.saveToken(token);
          setState(() => _isLoggedIn = true);
          return;
        } else {
          debugPrint('Token exchange misslyckades: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('Token exchange-fel: $e');
      }
    }

    // Annars kolla om den minns! (Info till Emma: All funktionalitet finns sparad som innan för din ändring, bara kombinerad inför merge) /EF
    final rememberMe = await TokenService.getRememberMe();
    if (rememberMe) {
      final savedToken = await TokenService.getToken();
      if (savedToken != null && savedToken.isNotEmpty) {
        setState(() => _isLoggedIn = true);
      }
    }
  }

  // 2. Funktion som anropas från WelcomeScreen vid lyckad inloggning/reg
  void _handleLoginSuccess() {
    setState(() {
      _isLoggedIn = true;
    });
  }
  void _handleLogout() async {
    await TokenService.deleteToken();
    setState(() {
      _isLoggedIn = false;
    });

  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WingLog',
      debugShowCheckedModeBanner: false, // Tar bort debug-banderollen
        theme: AppTheme.lightTheme,

      // 3. LOGIKEN: Om inloggad -> Hem, annars -> Welcome (Login)
      home: _isLoggedIn
          ? MainLayout(  // ÄNDRA HÄR!
        onLogout: _handleLogout,
      )
          : WelcomeScreen(
        onLoginSuccess: _handleLoginSuccess,
      ),
    );
  }
}