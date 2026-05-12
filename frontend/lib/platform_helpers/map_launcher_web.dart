
import 'package:web/web.dart' as web;

void openGoogleMapsNavigation(double lat, double lng) {
  final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';

  // Vi använder nu web.window istället för html.window
  web.window.open(url, '_blank');
}