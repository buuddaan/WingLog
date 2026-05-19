import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';

Future<void> openGoogleMapsNavigation(double lat, double lng) async {
  // Skapar universella länkar för både Apple och Google
  final String googleMapsUrl = "https://www.google.com/maps/search/?api=1&query=$lat,$lng";
  final String appleMapsUrl = "https://maps.apple.com/?q=$lat,$lng";

  try {
    if (Platform.isIOS) {
      // Om det är en iPhone, försök öppna Apple Maps först
      final Uri appleUri = Uri.parse(appleMapsUrl);
      if (await canLaunchUrl(appleUri)) {
        // LaunchMode.externalApplication tvingar telefonen att öppna den riktiga appen
        await launchUrl(appleUri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    // För Android (eller om Apple Maps misslyckades på iOS), använd Google Maps
    final Uri googleUri = Uri.parse(googleMapsUrl);
    if (await canLaunchUrl(googleUri)) {
      await launchUrl(googleUri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Kunde inte öppna någon kart-app.');
    }
  } catch (e) {
    debugPrint('Fel vid öppning av karta: $e');
  }
}