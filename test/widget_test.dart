// Smoke test: the landing page renders its section navigation cards.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schlierelacht_app/screens/landing_screen.dart';

void main() {
  testWidgets('LandingScreen shows the section cards',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LandingScreen()));

    // Cards near the top of the (lazily built) grid render their labels.
    expect(find.text('News'), findsOneWidget);
    expect(find.text('Programm'), findsOneWidget);
    expect(find.text('Gastro'), findsOneWidget);
  });
}
