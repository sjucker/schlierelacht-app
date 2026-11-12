// Smoke test: the landing page renders the festival banner and its section
// navigation cards.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:schlierelacht_app/screens/landing_screen.dart';

void main() {
  setUpAll(() => initializeDateFormatting('de_CH'));

  testWidgets('LandingScreen shows the banner and the section cards', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LandingScreen()));

    expect(find.text('Freier Eintritt zu allen Konzerten'), findsOneWidget);

    // Cards near the top of the (lazily built) grid render their labels.
    expect(find.text('News'), findsOneWidget);
    expect(find.text('Programm'), findsOneWidget);
    expect(find.text('Favoriten'), findsOneWidget);

    // Sections further down are reachable by scrolling.
    await tester.scrollUntilVisible(find.text('FAQ'), 300);
    expect(find.text('Über uns'), findsOneWidget);
    expect(find.text('Sponsoren'), findsOneWidget);
    expect(find.text('Gastro'), findsOneWidget);
  });
}
