// Meldungen: the model, the landing-page card (most important one only) and
// the list screen.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schlierelacht_app/api/message_api.dart';
import 'package:schlierelacht_app/models/message.dart';
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
    Message(id: id, priority: priority, title: title, content: 'Inhalt von **$title**', createdAt: DateTime(2027, 9, 3, 18));

void main() {
  test('fromJson', () {
    final m = Message.fromJson({'id': 7, 'priority': 'HIGH', 'title': 'Unwetter', 'content': '**Bitte** Zelte verlassen', 'createdAt': '2027-09-03T18:30:00'});
    expect(m.id, 7);
    expect(m.priority, MessagePriority.high);
    expect(m.title, 'Unwetter');
    expect(m.content, '**Bitte** Zelte verlassen');
    expect(m.createdAt, DateTime(2027, 9, 3, 18, 30));
  });

  test('priorities, unknown ones count as low', () {
    expect(MessagePriority.fromJson('MEDIUM'), MessagePriority.medium);
    expect(MessagePriority.fromJson('LOW'), MessagePriority.low);
    expect(MessagePriority.fromJson('CRITICAL'), MessagePriority.low);
  });

  testWidgets('the card shows the first message and links to all', (tester) async {
    final api = _FakeMessageApi([_message(1, MessagePriority.high, 'Unwetter'), _message(2, MessagePriority.low, 'Shuttlebus')]);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MessageCard(api: api)),
      ),
    );
    await tester.pump();

    expect(find.text('Unwetter'), findsOneWidget);
    expect(find.text('NOTFALL'), findsOneWidget);
    expect(find.text('Shuttlebus'), findsNothing, reason: 'only the most important one');
    expect(find.text('Alle Meldungen (2)'), findsOneWidget);
  });

  testWidgets('a single message has no "Alle Meldungen" link', (tester) async {
    final api = _FakeMessageApi([_message(1, MessagePriority.medium, 'Bühne verspätet')]);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MessageCard(api: api)),
      ),
    );
    await tester.pump();

    expect(find.text('WARNUNG'), findsOneWidget);
    expect(find.textContaining('Alle Meldungen'), findsNothing);
  });

  testWidgets('no active message: the card takes no space', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MessageCard(api: _FakeMessageApi([]))),
      ),
    );
    await tester.pump();

    expect(find.byType(MessageBox), findsNothing);
  });

  testWidgets('the screen lists all, in the backend order', (tester) async {
    final api = _FakeMessageApi([_message(1, MessagePriority.high, 'Unwetter'), _message(2, MessagePriority.low, 'Shuttlebus')]);
    await tester.pumpWidget(MaterialApp(home: MessagesScreen(api: api)));
    await tester.pump();

    expect(find.text('Unwetter'), findsOneWidget);
    expect(find.text('Shuttlebus'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Unwetter')).dy, lessThan(tester.getTopLeft(find.text('Shuttlebus')).dy));
  });

  testWidgets('the screen without messages', (tester) async {
    await tester.pumpWidget(MaterialApp(home: MessagesScreen(api: _FakeMessageApi([]))));
    await tester.pump();

    expect(find.text('Im Moment gibt es keine Meldungen.'), findsOneWidget);
  });

  test('push route "meldungen" opens the screen', () {
    expect(deepLinkPage('meldungen'), isA<MessagesScreen>());
    expect(deepLinkPage('/meldungen'), isA<MessagesScreen>());
  });
}
