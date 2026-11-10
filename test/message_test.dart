// Meldungen: the model, the landing-page card (most important title only), the detail and
// the list screen.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:schlierelacht_app/api/message_api.dart';
import 'package:schlierelacht_app/models/message.dart';
import 'package:schlierelacht_app/screens/message_detail_screen.dart';
import 'package:schlierelacht_app/screens/messages_screen.dart';
import 'package:schlierelacht_app/utils/deep_links.dart';
import 'package:schlierelacht_app/widgets/message_card.dart';

class _FakeMessageApi extends MessageApi {
  _FakeMessageApi(this.messages);

  List<Message> messages;

  @override
  Future<List<Message>> fetchActive() async => messages;
}

Message _message(int id, MessagePriority priority, String title) =>
    Message(id: id, priority: priority, title: title, content: 'Inhalt von **$title**', publishedAt: DateTime(2027, 9, 3, 18));

void main() {
  setUpAll(() => initializeDateFormatting('de_CH'));

  test('fromJson', () {
    final json = {
      'id': 7,
      'priority': 'HIGH',
      'title': 'Unwetter',
      'content': '**Bitte** Zelte verlassen',
      'createdAt': '2027-09-01T09:00:00',
      'publishedAt': '2027-09-03T18:30:00.123456',
    };
    final m = Message.fromJson(json);
    expect(m.id, 7);
    expect(m.priority, MessagePriority.high);
    expect(m.title, 'Unwetter');
    expect(m.content, '**Bitte** Zelte verlassen');
    expect(m.publishedAt, DateTime(2027, 9, 3, 18, 30, 0, 123, 456), reason: 'the publish time, not the creation time');

    // A backend from before publishedAt: fall back to the creation time.
    expect(Message.fromJson({...json}..remove('publishedAt')).publishedAt, DateTime(2027, 9, 1, 9));
  });

  test('priorities, unknown ones count as low', () {
    expect(MessagePriority.fromJson('MEDIUM'), MessagePriority.medium);
    expect(MessagePriority.fromJson('LOW'), MessagePriority.low);
    expect(MessagePriority.fromJson('CRITICAL'), MessagePriority.low);
  });

  testWidgets('the card shows only the first title and links to all', (tester) async {
    final api = _FakeMessageApi([_message(1, MessagePriority.high, 'Unwetter'), _message(2, MessagePriority.low, 'Shuttlebus')]);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MessageCard(api: api)),
      ),
    );
    await tester.pump();

    expect(find.text('Unwetter'), findsOneWidget);
    expect(find.textContaining('Inhalt von', findRichText: true), findsNothing, reason: 'title only');
    expect(find.text('Shuttlebus'), findsNothing, reason: 'only the most important one');
    expect(find.text('Alle Meldungen (2)'), findsOneWidget);
  });

  testWidgets('a single message still links to the overview', (tester) async {
    final api = _FakeMessageApi([_message(1, MessagePriority.medium, 'Bühne verspätet')]);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MessageCard(api: api)),
      ),
    );
    await tester.pump();

    expect(find.text('Alle Meldungen'), findsOneWidget);
  });

  testWidgets('tapping the card opens the message with its content', (tester) async {
    final api = _FakeMessageApi([_message(1, MessagePriority.high, 'Unwetter')]);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MessageCard(api: api)),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Unwetter'));
    await tester.pumpAndSettle();

    expect(find.byType(MessageDetailScreen), findsOneWidget);
    expect(find.text('NOTFALL'), findsOneWidget);
    expect(find.text('Unwetter'), findsOneWidget);
    expect(find.textContaining('Inhalt von', findRichText: true), findsOneWidget);
    expect(find.text('Veröffentlicht am 03.09.2027, 18:00'), findsOneWidget);
  });

  testWidgets('no active message: the card takes no space', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MessageCard(api: _FakeMessageApi([]))),
      ),
    );
    await tester.pump();

    expect(find.byType(MessageTitleCard), findsNothing);
    expect(find.textContaining('Alle Meldungen'), findsNothing);
  });

  testWidgets('the screen lists all, in the backend order', (tester) async {
    final api = _FakeMessageApi([_message(1, MessagePriority.high, 'Unwetter'), _message(2, MessagePriority.low, 'Shuttlebus')]);
    await tester.pumpWidget(MaterialApp(home: MessagesScreen(api: api)));
    await tester.pump();

    expect(find.text('Unwetter'), findsOneWidget);
    expect(find.text('Shuttlebus'), findsOneWidget);
    expect(find.textContaining('Veröffentlicht am'), findsNothing, reason: 'only the detail view shows the date');
    expect(tester.getTopLeft(find.text('Unwetter')).dy, lessThan(tester.getTopLeft(find.text('Shuttlebus')).dy));
  });

  testWidgets('the screen without messages', (tester) async {
    await tester.pumpWidget(MaterialApp(home: MessagesScreen(api: _FakeMessageApi([]))));
    await tester.pump();

    expect(find.text('Im Moment gibt es keine Meldungen.'), findsOneWidget);
  });

  testWidgets('markdown headings, bold and text use the card text color', (tester) async {
    final message = Message(id: 1, priority: MessagePriority.high, title: 'Unwetter', content: '# Kopf\n\n**Fett** und Text', publishedAt: DateTime(2027));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MessageBox(message: message)),
      ),
    );

    final context = tester.element(find.byType(MessageBox));
    final expected = Theme.of(context).colorScheme.onError; // HIGH: white on the error red
    for (final word in ['Kopf', 'Fett', 'Text']) {
      expect(_colorOf(tester, word), expected, reason: word);
    }
  });

  test('push route "meldungen" opens the screen', () {
    expect(deepLinkPage('meldungen'), isA<MessagesScreen>());
    expect(deepLinkPage('/meldungen'), isA<MessagesScreen>());
  });
}

/// The color the markdown text span containing [word] is painted in.
Color? _colorOf(WidgetTester tester, String word) {
  final rich = tester.widget<RichText>(find.textContaining(word, findRichText: true).first);
  Color? color;
  rich.text.visitChildren((span) {
    if (span is TextSpan && (span.text ?? '').contains(word)) {
      color = span.style?.color;
      return false;
    }
    return true;
  });
  return color ?? rich.text.style?.color;
}
