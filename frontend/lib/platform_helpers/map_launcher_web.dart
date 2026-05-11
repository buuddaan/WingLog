// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void openGoogleMapsNavigation(double lat, double lng) {
  final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving';
  html.window.open(url, '_blank');
}
