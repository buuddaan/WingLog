import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // ===================================================================
  // STRÖMBRYTAREN:
  // Ändra till 'true' när du kodar lokalt mot Docker på din Mac.
  // Ändra till 'false' när du vill bygga/testa mot den skarpa servern!
  // ===================================================================
  static const bool useLocalBackend = true;

  // Din Macs lokala IP på nätverket (byt om du byter Wi-Fi)
  static const String _macLocalIp = '10.200.46.110';

  static String get baseUrl {
    if (!useLocalBackend) {
      // ---------------------------------------------------
      // SKARPT LÄGE: Alla enheter pekar på live-servern
      // ---------------------------------------------------
      return 'https://winglog.duckdns.org/gateway';
    } else {
      // ---------------------------------------------------
      // LOKALT LÄGE: Appen letar efter Docker på din Mac
      // ---------------------------------------------------
      if (kIsWeb) {
        // Chrome på Macen hittar Docker direkt på localhost
        return 'http://localhost:8080/gateway';
      }
      else if (Platform.isAndroid) {
        // Android-emulatorns inbyggda magiska adress för att nå Macen
        return 'http://10.0.2.2:8080/gateway';
      }
      else {
        // För fysisk iPhone OCH iOS-simulatorn.
        // Vi använder din lokala IP här så att det funkar om du
        // pluggar in telefonen med sladd också!
        return 'http://$_macLocalIp:8080/gateway';
      }
    }
  }
}