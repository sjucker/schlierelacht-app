// Dark mode: what must stay readable on the navy background.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schlierelacht_app/services/prefs.dart';
import 'package:schlierelacht_app/theme.dart';
import 'package:schlierelacht_app/widgets/favorite_button.dart';
import 'package:schlierelacht_app/widgets/fest_logo.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Widget dark(Widget body) => MaterialApp(
    theme: buildFestDarkTheme(),
    home: Scaffold(body: body),
  );

  bool onWhiteCard(WidgetTester tester) => find
      .ancestor(of: find.byType(Image), matching: find.byType(DecoratedBox))
      .evaluate()
      .any((e) => ((e.widget as DecoratedBox).decoration as BoxDecoration).color == Colors.white);

  testWidgets('the black-lettered logo sits on a white card in dark mode only', (tester) async {
    await tester.pumpWidget(dark(const FestLogo(height: 100)));
    expect(onWhiteCard(tester), isTrue);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildFestTheme(),
        home: const Scaffold(body: FestLogo(height: 100)),
      ),
    );
    await tester.pumpAndSettle(); // MaterialApp animates the theme change
    expect(onWhiteCard(tester), isFalse);
  });

  testWidgets('an active favorite is yellow in a dark list row', (tester) async {
    SharedPreferences.setMockInitialValues({
      'favorites': ['A1'],
    });
    await Prefs.init();
    await tester.pumpWidget(
      dark(
        const ListTile(
          title: Text('Act'),
          trailing: FavoriteButton(externalId: 'A1'),
        ),
      ),
    );
    expect(tester.widget<IconButton>(find.byType(IconButton)).color, FestColors.yellow);
  });
}
