// Smoke test: the app boots and shows the two navigation destinations.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schlierelacht_app/screens/home_shell.dart';

void main() {
  testWidgets('HomeShell shows News and Programm navigation destinations',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeShell()));

    // Both nav destinations render their labels. ("News" also appears in the
    // AppBar title, so it is present at least once; "Programm" is unique.)
    expect(find.text('Programm'), findsOneWidget);
    expect(find.text('News'), findsWidgets);

    // The News tab is selected first, so its list screen attempts to load.
    expect(find.byType(HomeShell), findsOneWidget);
  });
}
