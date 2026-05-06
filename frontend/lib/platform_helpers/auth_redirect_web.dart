import 'package:web/web.dart' as web;

void redirectToGoogleAuth() {
  web.window.location.href = 'http://localhost:8081/oauth2/authorization/google';
}