
class ApiConfig {
  // Byt ut detta mot den PUBLIKA IP-adressen till din SSH-server
  static const String _serverIp = '123.45.67.89';

  static String get baseUrl {
    // Nu behöver vi inga if-satser längre. Alla enheter når servern på samma sätt!
    return 'http://$_serverIp:8080/gateway';
  }
}