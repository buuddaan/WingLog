import 'package:flutter/foundation.dart';

class ApiConfig {
  // Hämtar värdena från din .env-fil vid kompilering
  static const bool useLocalBackend = bool.fromEnvironment(
    'USE_LOCAL_BACKEND',
  );

  static const String _prodBaseUrl = String.fromEnvironment(
    'PROD_BASE_URL',
  );

  static const String _localhost = String.fromEnvironment(
    'LOCALHOST',
  );

  static const String _phoneDeployed = String.fromEnvironment(
    'PHONE_DEPLOYED',
  );

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