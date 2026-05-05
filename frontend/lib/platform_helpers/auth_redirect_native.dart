import 'package:url_launcher/url_launcher.dart';

void redirectToGoogleAuth() async {
  final Uri url = Uri.parse('http://localhost:8081/oauth2/authorization/google');

  // Öppnar Macens standardwebbläsare (t.ex. Safari eller Chrome)
  if (!await launchUrl(url)) {
    throw Exception('Kunde inte öppna webbläsaren');
  }
}