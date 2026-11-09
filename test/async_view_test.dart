// AsyncView keeps the data on screen while a new future (pull-to-refresh)
// loads, and only shows the error state when there is nothing to show.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schlierelacht_app/widgets/async_view.dart';

void main() {
  // The screen's `_future` field: swapping it is what `_reload()` does.
  late ValueNotifier<Future<String>> future;

  Future<void> pumpHost(WidgetTester tester, Future<String> initial) {
    future = ValueNotifier(initial);
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ValueListenableBuilder<Future<String>>(
            valueListenable: future,
            builder: (_, f, _) => AsyncView<String>(future: f, onRetry: () {}, onData: (_, data) => Text(data)),
          ),
        ),
      ),
    );
  }

  testWidgets('first load: spinner, then the data', (tester) async {
    final load = Completer<String>();
    await pumpHost(tester, load.future);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    load.complete('v1');
    await tester.pump();
    expect(find.text('v1'), findsOneWidget);
  });

  testWidgets('a reload keeps the old data until the new data is in', (tester) async {
    await pumpHost(tester, Future.value('v1'));
    await tester.pump();

    final reload = Completer<String>();
    future.value = reload.future;
    await tester.pump();
    expect(find.text('v1'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    reload.complete('v2');
    await tester.pump(); // microtask: the future settles
    await tester.pump(); // frame: rebuilt with the new data
    expect(find.text('v2'), findsOneWidget);
  });

  testWidgets('a failed reload keeps the old data and says so', (tester) async {
    await pumpHost(tester, Future.value('v1'));
    await tester.pump();

    final reload = Completer<String>();
    future.value = reload.future;
    await tester.pump();
    reload.completeError(Exception('offline'));
    await tester.pump(); // microtask: the future settles
    await tester.pump(); // frame: rebuilt, SnackBar requested post-frame
    await tester.pump(); // SnackBar shown
    expect(find.text('v1'), findsOneWidget);
    expect(find.text('Aktualisierung fehlgeschlagen.'), findsOneWidget);
  });

  testWidgets('a failed first load shows the retry state', (tester) async {
    final load = Completer<String>();
    await pumpHost(tester, load.future);
    load.completeError(Exception('offline'));
    await tester.pump();
    expect(find.text('Erneut versuchen'), findsOneWidget);
  });

  test('settled completes normally even when the future fails', () async {
    await expectLater(settled(Future<void>.error(Exception('x'))), completes);
  });
}
