
class ApiConfig {
  // Byt ut detta mot den PUBLIKA IP-adressen till din SSH-server
  static const String _serverIp = '123.45.67.89';

  static String get baseUrl {
    // Webbläsaren (Chrome) körs på datorn och hittar din backend via localhost.
    if (kIsWeb) {
      return 'http://65.21.190.58:8080/gateway';
    }
    // Android-emulatorer har en inbyggd spärr och måste använda en special-adress
    // (10.0.2.2) för att hitta värddatorns localhost.
    else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080/gateway';
    }
    // telefoner är egna datorer på nätverket och måste peka på din dators IP.
    else {
      return 'http://$_localIpAddress:8080/gateway';
    }
  }
}