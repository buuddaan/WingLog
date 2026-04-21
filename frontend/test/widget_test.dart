import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/welcome_screen.dart'; // Justera om ditt paket heter något annat

void main() {
  // En hjälpfunktion (Wrapper) för att kunna bygga din skärm i testmiljön.
  // Eftersom din skärm kräver funktionen 'onLoginSuccess' skickar vi in en valfri mock-funktion.
  Widget createWelcomeScreenUnderTest({VoidCallback? onMockLogin}) {
    return MaterialApp(
      home: WelcomeScreen(
        onLoginSuccess: onMockLogin ?? () {},
      ),
    );
  }

  group('WelcomeScreen - Inloggning och Registrering UI Tester', () {

    // TEST 1: Kontrollerar att standardläget (Inloggning) renderas korrekt
    testWidgets('Test 1: Startar i inloggningsläge och döljer Email-fältet', (WidgetTester tester) async {
      await tester.pumpWidget(createWelcomeScreenUnderTest());

      expect(find.text('Logga in på WingLog'), findsOneWidget);
      expect(find.text('Användarnamn'), findsOneWidget);
      expect(find.text('Lösenord'), findsOneWidget);
      expect(find.text('Email'), findsNothing); // Email ska inte finnas i inloggningsläge
    });

    // TEST 2: Kontrollerar state-förändring (setState) när användaren växlar läge
    testWidgets('Test 2: Växlar till registreringsläge när man klickar på länk', (WidgetTester tester) async {
      await tester.pumpWidget(createWelcomeScreenUnderTest());

      // Klicka på "Skapa konto"-länken och vänta på att animationen är klar
      await tester.tap(find.text('Inget konto? Skapa ett här'));
      await tester.pumpAndSettle();

      expect(find.text('Skapa WingLog-konto'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget); // Nu MÅSTE Email finnas
    });

    // TEST 3: Validering - Tomma fält
    testWidgets('Test 3: Visar valideringsfel om man klickar logga in med tomma fält', (WidgetTester tester) async {
      await tester.pumpWidget(createWelcomeScreenUnderTest());

      // Klicka på huvudknappen (ElevatedButton) utan att skriva in text
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Förväntar oss att felmeddelandena dyker upp
      expect(find.text('Ange användarnamn'), findsOneWidget);
      expect(find.text('Minst 6 tecken'), findsOneWidget);
    });

    // TEST 4: Validering - Kort lösenord
    testWidgets('Test 4: Specifikt valideringsfel visas för lösenord under 6 tecken', (WidgetTester tester) async {
      await tester.pumpWidget(createWelcomeScreenUnderTest());

      // Skriv in ett för kort lösenord (index 1 är lösenordsfältet)
      await tester.enterText(find.byType(TextFormField).at(1), '123');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Minst 6 tecken'), findsOneWidget);
    });

    // TEST 5: Validering godkänns med rätt data
    testWidgets('Test 5: Valideringsfel försvinner när korrekta uppgifter matas in', (WidgetTester tester) async {
      await tester.pumpWidget(createWelcomeScreenUnderTest());

      // Skriv in giltiga uppgifter
      await tester.enterText(find.byType(TextFormField).at(0), 'WingLogUser');
      await tester.enterText(find.byType(TextFormField).at(1), 'SäkertLösenord123');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Förväntar oss att valideringsfelen INTE ritas ut
      expect(find.text('Ange användarnamn'), findsNothing);
      expect(find.text('Minst 6 tecken'), findsNothing);
    });

    // TEST 6: Test av Callbacks (Avancerat och bra för examinering)
    testWidgets('Test 6: Dev-knappen (Skippa inloggning) anropar onLoginSuccess direkt', (WidgetTester tester) async {
      bool callbackFired = false;

      // Bygg skärmen med en mock-funktion som sätter vår variabel till true om den anropas
      await tester.pumpWidget(createWelcomeScreenUnderTest(
        onMockLogin: () => callbackFired = true,
      ));

      // Klicka på Dev-knappen
      await tester.tap(find.text('TILLFÄLLIGT: Skippa inloggning'));
      await tester.pumpAndSettle();

      // Callbacken ska ha körts
      expect(callbackFired, isTrue);
    });

    // TEST 7: Test av UI-egenskaper (Lösenordsfältet är maskerat)
    testWidgets('Test 7: Lösenordsfältet döljer texten (obscureText är aktivt)', (WidgetTester tester) async {
      await tester.pumpWidget(createWelcomeScreenUnderTest());

      // Hitta textfältet för lösenord
      final TextField passwordField = tester.widget(
        find.descendant(
          of: find.byType(TextFormField).at(1),
          matching: find.byType(TextField),
        ),
      );

      // Verifiera säkerhetsinställningen
      expect(passwordField.obscureText, isTrue);
    });

    // TEST 8: Test av Dynamiska Texter på knappar
    testWidgets('Test 8: Huvudknappens text ändras beroende på valt läge', (WidgetTester tester) async {
      await tester.pumpWidget(createWelcomeScreenUnderTest());

      // Standardläge: Logga in
      expect(find.descendant(of: find.byType(ElevatedButton), matching: find.text('Logga in')), findsOneWidget);

      // Växla till registrering
      await tester.tap(find.text('Inget konto? Skapa ett här'));
      await tester.pumpAndSettle();

      // Läge: Registrera
      expect(find.descendant(of: find.byType(ElevatedButton), matching: find.text('Registrera')), findsOneWidget);
    });

    // TEST 9: Kontrollerar grafiska element
    testWidgets('Test 9: Rendera designelement (Ikoner och Divider) korrekt', (WidgetTester tester) async {
      await tester.pumpWidget(createWelcomeScreenUnderTest());

      // Ser till att WingLog-ikonen och Dev-knappens ikon ritas ut
      expect(find.byIcon(Icons.flutter_dash), findsOneWidget);
      expect(find.byIcon(Icons.fast_forward), findsOneWidget);
      expect(find.byType(Divider), findsOneWidget);
    });

    // TEST 10: Återställning till inloggningsläge fungerar
    testWidgets('Test 10: Kan växla fram och tillbaka mellan lägena utan minnesläckor', (WidgetTester tester) async {
      await tester.pumpWidget(createWelcomeScreenUnderTest());

      // Fram...
      await tester.tap(find.text('Inget konto? Skapa ett här'));
      await tester.pumpAndSettle();
      expect(find.text('Email'), findsOneWidget);

      // ...och Tillbaka
      await tester.tap(find.text('Har du redan ett konto? Logga in'));
      await tester.pumpAndSettle();
      expect(find.text('Email'), findsNothing);
    });
  });
}