import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // Byt ut detta mot din dators aktuella IP-adress!
  static const String _localIpAddress = '192.168.1.209';

  static String get baseUrl {
    // 1. KÖR VI PÅ WEBBEN?
    // Webbläsaren (Chrome) körs på datorn och hittar din backend via localhost.
    if (kIsWeb) {
      return 'http://localhost:8080/gateway';
    }

    // 2. KÖR VI I EN ANDROID-EMULATOR PÅ DATORN?
    // Android-emulatorer har en inbyggd spärr och måste använda en special-adress
    // (10.0.2.2) för att hitta värddatorns localhost.
    else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080/gateway';
    }

    // 3. KÖR VI PÅ EN FYSISK iPHONE (eller Android-telefon)?
    // Fysiska enheter är egna datorer på nätverket och måste peka på din dators IP.
    else {
      return 'http://$_localIpAddress:8080/gateway';
    }
  }
}