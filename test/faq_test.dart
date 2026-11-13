// FAQ: the model, the search filter and the screen (group headers, expanding
// answers, search).
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schlierelacht_app/api/faq_api.dart';
import 'package:schlierelacht_app/models/faq.dart';
import 'package:schlierelacht_app/screens/faq_screen.dart';
import 'package:schlierelacht_app/utils/deep_links.dart';

class _FakeFaqApi extends FaqApi {
  _FakeFaqApi(this.groups);

  final List<FaqGroup> groups;

  @override
  Future<List<FaqGroup>> fetchFaq() async => groups;
}

final _groups = [
  const FaqGroup(
    name: 'Anreise',
    entries: [
      FaqEntry(id: 1, title: 'Wie komme ich mit dem ÖV?', content: 'Mit der **S-Bahn** bis Schlieren.'),
      FaqEntry(id: 2, title: 'Wo kann ich parkieren?', content: 'Es gibt keine Parkplätze.'),
    ],
  ),
  const FaqGroup(
    name: 'Verpflegung',
    entries: [FaqEntry(id: 3, title: 'Kann ich mit Karte zahlen?', content: 'Ja, mit TWINT und Karte.')],
  ),
];

void main() {
  test('fromJson', () {
    final group = FaqGroup.fromJson({
      'name': 'Anreise',
      'entries': [
        {'id': 1, 'title': 'Wie komme ich hin?', 'content': '**Zu Fuss**'},
      ],
    });
    expect(group.name, 'Anreise');
    expect(group.entries.single.id, 1);
    expect(group.entries.single.title, 'Wie komme ich hin?');
    expect(group.entries.single.content, '**Zu Fuss**');
  });

  test('filterFaq: question and answer, case-insensitive, empty groups dropped', () {
    expect(filterFaq(_groups, ''), same(_groups));
    expect(filterFaq(_groups, '  '), same(_groups));

    final byTitle = filterFaq(_groups, 'PARKIEREN');
    expect(byTitle.single.name, 'Anreise');
    expect(byTitle.single.entries.single.id, 2);

    final byContent = filterFaq(_groups, 'twint');
    expect(byContent.single.name, 'Verpflegung');

    expect(filterFaq(_groups, 'Hunde'), isEmpty);
  });

  testWidgets('groups with their questions; a tap shows the answer', (tester) async {
    await tester.pumpWidget(MaterialApp(home: FaqScreen(api: _FakeFaqApi(_groups))));
    await tester.pump();

    expect(find.text('ANREISE'), findsOneWidget);
    expect(find.text('VERPFLEGUNG'), findsOneWidget);
    expect(find.text('Wo kann ich parkieren?'), findsOneWidget);
    expect(find.textContaining('keine Parkplätze', findRichText: true), findsNothing, reason: 'collapsed');

    await tester.tap(find.text('Wo kann ich parkieren?'));
    await tester.pumpAndSettle();
    expect(find.textContaining('keine Parkplätze', findRichText: true), findsOneWidget);
  });

  testWidgets('search filters and shows the matches expanded', (tester) async {
    await tester.pumpWidget(MaterialApp(home: FaqScreen(api: _FakeFaqApi(_groups))));
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'twint');
    await tester.pumpAndSettle();
    expect(find.text('ANREISE'), findsNothing);
    expect(find.text('Kann ich mit Karte zahlen?'), findsOneWidget);
    expect(find.textContaining('TWINT', findRichText: true), findsOneWidget, reason: 'match shown expanded');

    await tester.enterText(find.byType(TextField), 'Hunde');
    await tester.pumpAndSettle();
    expect(find.text('Keine Treffer.'), findsOneWidget);
  });

  testWidgets('no entries yet', (tester) async {
    await tester.pumpWidget(MaterialApp(home: FaqScreen(api: _FakeFaqApi(const []))));
    await tester.pump();

    expect(find.text('Im Moment sind keine Fragen erfasst.'), findsOneWidget);
    expect(find.byType(SearchBar), findsNothing);
  });

  test('push route "faq" opens the screen', () {
    expect(deepLinkPage('faq'), isA<FaqScreen>());
    expect(deepLinkPage('/faq'), isA<FaqScreen>());
  });
}
