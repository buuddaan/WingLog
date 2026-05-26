import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/services/token_service.dart';

void main() {
  // Körs före varje test, precis som @BeforeEach i JUnit
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TokenService Tests', () {
    test('1. getToken() ska returnera null om ingen token är sparad', () async {
      final token = await TokenService.getToken();
      expect(token, isNull);
    });

    test('2. saveToken() ska spara token korrekt', () async {
      await TokenService.saveToken('test_jwt_token');
      final token = await TokenService.getToken();
      expect(token, 'test_jwt_token');
    });

    test('3. saveToken() ska skriva över en gammal token', () async {
      await TokenService.saveToken('old_token');
      await TokenService.saveToken('new_token');
      final token = await TokenService.getToken();
      expect(token, 'new_token');
    });

    test('4. deleteToken() ska ta bort sparad token', () async {
      await TokenService.saveToken('test_jwt_token');
      await TokenService.deleteToken();
      final token = await TokenService.getToken();
      expect(token, isNull);
    });

    test('5. getRememberMe() ska returnera false som standard', () async {
      final rememberMe = await TokenService.getRememberMe();
      expect(rememberMe, isFalse);
    });

    test('6. saveRememberMe(true) ska spara true', () async {
      await TokenService.saveRememberMe(true);
      final rememberMe = await TokenService.getRememberMe();
      expect(rememberMe, isTrue);
    });

    test('7. saveRememberMe(false) ska spara false', () async {
      await TokenService.saveRememberMe(true); // Sätt till true först
      await TokenService.saveRememberMe(false); // Ändra till false
      final rememberMe = await TokenService.getRememberMe();
      expect(rememberMe, isFalse);
    });

    test('8. deleteToken() ska ÄVEN ta bort rememberMe-valet', () async {
      await TokenService.saveRememberMe(true);
      await TokenService.deleteToken();
      final rememberMe = await TokenService.getRememberMe();
      expect(rememberMe, isFalse); // Ska återgå till default (false)
    });
  });
}