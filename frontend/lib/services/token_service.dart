import 'package:shared_preferences/shared_preferences.dart';

class TokenService {
  static const String tokenKey = 'jwt_token';

  //spara token efter inlogg
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  //hämta token vid API anrop
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  //radera token vid utloggning
  static Future<void> deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
  }
}