import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/design_system/atoms/app_text.dart';
import 'package:frontend/design_system/atoms/primary_gradient_button.dart';
import 'package:frontend/design_system/atoms/danger_button.dart';
import 'package:frontend/design_system/atoms/app_close_button.dart';
import 'package:frontend/design_system/molecules/loading_overlay.dart';
import 'package:frontend/design_system/molecules/section_header.dart';
import 'package:frontend/design_system/molecules/selection_action_row.dart';

void main() {
  group('Atoms (Enkla komponenter)', () {
    testWidgets('17. AppText.title ska rendera rätt text', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: AppText.title('Hejsan')));
      expect(find.text('Hejsan'), findsOneWidget);
    });

    testWidgets('18. AppCloseButton ska rendera en klickbar stäng-ikon', (WidgetTester tester) async {
      bool wasPressed = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: AppCloseButton(onPressed: () => wasPressed = true)),
      ));

      final iconButton = find.byIcon(Icons.close);
      expect(iconButton, findsOneWidget);

      await tester.tap(iconButton);
      expect(wasPressed, isTrue, reason: '19. Callbacken onPressed ska köras vid klick');
    });

    testWidgets('20. PrimaryGradientButton ska visa text', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: PrimaryGradientButton.filled(text: 'Logga in', onPressed: () {}),
      ));
      expect(find.text('Logga in'), findsOneWidget);
    });

    testWidgets('21. PrimaryGradientButton triggar onPressed vid klick', (WidgetTester tester) async {
      bool pressed = false;
      await tester.pumpWidget(MaterialApp(
        home: PrimaryGradientButton.filled(text: 'Klick', onPressed: () => pressed = true),
      ));
      await tester.tap(find.text('Klick'));
      expect(pressed, isTrue);
    });

    testWidgets('22. En inaktiverad PrimaryGradientButton triggar ej onPressed', (WidgetTester tester) async {
      bool pressed = false;
      await tester.pumpWidget(MaterialApp(
        home: PrimaryGradientButton.filled(text: 'Inaktiv', onPressed: null),
      ));
      await tester.tap(find.text('Inaktiv'));
      expect(pressed, isFalse);
    });

    testWidgets('23. DangerButton.small visar text', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: DangerButton.small(text: 'Radera', onPressed: () {}),
      ));
      expect(find.text('Radera'), findsOneWidget);
    });

    testWidgets('24. DangerButton.medium triggar action', (WidgetTester tester) async {
      bool pressed = false;
      await tester.pumpWidget(MaterialApp(
        home: DangerButton.medium(text: 'Radera', onPressed: () => pressed = true),
      ));
      await tester.tap(find.text('Radera'));
      expect(pressed, isTrue);
    });
  });

  group('Molecules (Sammansatta komponenter)', () {
    testWidgets('25. LoadingOverlay renderar en CircularProgressIndicator', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoadingOverlay()));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('26. SectionHeader visar titel', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: SectionHeader(title: 'Mina Bilder')),
      ));
      expect(find.text('Mina Bilder'), findsOneWidget);
    });

    testWidgets('27. SectionHeader visar subtitel om angivet', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: SectionHeader(title: 'Titel', subtitle: 'Subtitel')),
      ));
      expect(find.text('Subtitel'), findsOneWidget);
    });

    testWidgets('28. SectionHeader döljer subtitel om den är null', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: SectionHeader(title: 'Titel', subtitle: null)),
      ));
      // Den enda Text-widgeten ska vara Titeln (plus ev. ikoner)
      expect(find.byType(Text), findsNWidgets(1));
    });

    testWidgets('29. SelectionActionRow visar valt antal i Radera-knappen', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: SelectionActionRow(onBack: (){}, onDelete: (){}, selectedCount: 5)),
      ));
      expect(find.text('Radera (5)'), findsOneWidget);
    });

    testWidgets('30. SelectionActionRow triggar onBack', (WidgetTester tester) async {
      bool backPressed = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: SelectionActionRow(
            onBack: () => backPressed = true,
            onDelete: (){},
            selectedCount: 1
        )),
      ));
      await tester.tap(find.text('Tillbaka'));
      expect(backPressed, isTrue);
    });

    testWidgets('31. SelectionActionRow triggar onDelete', (WidgetTester tester) async {
      bool deletePressed = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: SelectionActionRow(
            onBack: (){},
            onDelete: () => deletePressed = true,
            selectedCount: 1
        )),
      ));
      await tester.tap(find.text('Radera (1)'));
      expect(deletePressed, isTrue);
    });
  });
}