// An active favorite must stay visible: yellow on the blue app bar, blue on
// light list rows.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schlierelacht_app/services/prefs.dart';
import 'package:schlierelacht_app/theme.dart';
import 'package:schlierelacht_app/widgets/favorite_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'favorites': ['A1'],
    });
    await Prefs.init();
  });

  Color? heartColor(WidgetTester tester) => tester.widget<Icon>(find.byIcon(Icons.favorite)).color ?? tester.widget<IconButton>(find.byType(IconButton)).color;

  testWidgets('active favorite is yellow in the blue app bar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFestTheme(),
        home: Scaffold(
          appBar: AppBar(actions: const [FavoriteButton(externalId: 'A1')]),
        ),
      ),
    );
    expect(heartColor(tester), FestColors.yellow);
  });

  testWidgets('active favorite is blue in a list row', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFestTheme(),
        home: const Scaffold(
          body: ListTile(
            title: Text('Act'),
            trailing: FavoriteButton(externalId: 'A1'),
          ),
        ),
      ),
    );
    expect(heartColor(tester), FestColors.blue);
  });
}
