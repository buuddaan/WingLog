import 'package:flutter/foundation.dart';

class ApiConfig {
static const bool useLocalBackend = true;

static const String _prodBaseUrl = 'https://winglog.duckdns.org/gateway';

static const String _localhost = 'http://localhost:8080/gateway';

static const String _phoneDeployed = 'http://192.168.1.241:8080/gateway';

  static String get baseUrl {
    if (!useLocalBackend) {
      // ---------------------------------------------------
      // SKARPT LÄGE: Alla enheter pekar på live-servern
      // ---------------------------------------------------
      if (_prodBaseUrl.isEmpty) {
        throw Exception('PROD_BASE_URL är inte satt i .env-filen!');
      }
      return _prodBaseUrl;
    } else {
      // ---------------------------------------------------
      // LOKALT LÄGE: Vi hämtar adresserna från .env
      // ---------------------------------------------------
      if (kIsWeb) {
        if (_localhost.isEmpty) {
          throw Exception('LOCALHOST är inte satt i .env-filen!');
        }
        return _localhost;
      }

      // Returnerar IP-adressen som behövs för fysisk enhet / emulator
      if (_phoneDeployed.isEmpty) {
        throw Exception('PHONE_DEPLOYED är inte satt i .env-filen!');
      }
      return _phoneDeployed;
    }
  }
}