// The schedule marks today's day header "HEUTE" and acts on stage "JETZT".
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:schlierelacht_app/models/now_playing.dart';
import 'package:schlierelacht_app/models/programm_entry.dart';
import 'package:schlierelacht_app/models/programm_point.dart';
import 'package:schlierelacht_app/models/schedule.dart';
import 'package:schlierelacht_app/services/prefs.dart';
import 'package:schlierelacht_app/widgets/schedule_day_section.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _date(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
String _time(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// An entry from [start] to [end] (or without an end time).
ProgrammPoint _point(String name, DateTime start, [DateTime? end]) => ProgrammPoint.fromJson({
  'attraction': {'externalId': name, 'name': name},
  'entry': {
    'location': {
      'externalId': 'L1',
      'type': 'STAGE',
      'name': 'Hauptbühne',
      'latitude': 47.39,
      'longitude': 8.44,
      'googleMapsUrl': 'https://maps.google.com/?q=1',
      'showInFestplan': true,
    },
    'fromDate': _date(start),
    'fromTime': _time(start),
    'toDate': end == null ? null : _date(end),
    'toTime': end == null ? null : _time(end),
    'past': false,
  },
});

ProgrammEntry _entry(DateTime start, [DateTime? end]) => _point('x', start, end).entry;

void main() {
  setUpAll(() => initializeDateFormatting('de_CH'));
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Prefs.init(); // FavoriteButton reads the favorites
  });

  test('isRunningAt: started and not over, like the Jetzt läuft card', () {
    final now = DateTime(2027, 9, 3, 20, 30);
    expect(isRunningAt(_entry(DateTime(2027, 9, 3, 20), DateTime(2027, 9, 3, 21)), now), isTrue);
    expect(isRunningAt(_entry(DateTime(2027, 9, 3, 21), DateTime(2027, 9, 3, 22)), now), isFalse, reason: 'not started');
    expect(isRunningAt(_entry(DateTime(2027, 9, 3, 19), DateTime(2027, 9, 3, 20, 30)), now), isFalse, reason: 'just ended');
    expect(isRunningAt(_entry(DateTime(2027, 9, 3, 20)), now), isTrue, reason: 'no end time: one hour');
    expect(isRunningAt(_entry(DateTime(2027, 9, 3, 19)), now), isFalse);
  });

  Future<void> pumpDay(WidgetTester tester, DateTime date, List<ProgrammPoint> points, {bool past = false}) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ScheduleDaySection(
          day: ScheduleDay(
            date: date,
            items: [for (final p in points) ScheduleItem(entry: p.entry, attraction: p.attraction)],
          ),
          onTapItem: (_) {},
          past: past,
        ),
      ),
    ),
  );

  testWidgets('HEUTE on today only, JETZT on the running act only', (tester) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    await pumpDay(tester, today, [
      _point('Running', now.subtract(const Duration(minutes: 10)), now.add(const Duration(minutes: 50))),
      _point('Later', now.add(const Duration(hours: 2)), now.add(const Duration(hours: 3))),
    ]);
    expect(find.text('HEUTE'), findsOneWidget);
    expect(find.text('JETZT'), findsOneWidget);
    expect(find.ancestor(of: find.text('JETZT'), matching: find.widgetWithText(ListTile, 'Running')), findsOneWidget);

    await pumpDay(tester, today.add(const Duration(days: 1)), [_point('Tomorrow', now.add(const Duration(days: 1)))]);
    expect(find.text('HEUTE'), findsNothing);
    expect(find.text('JETZT'), findsNothing);
  });

  testWidgets('the Vergangene group marks neither', (tester) async {
    final now = DateTime.now();
    await pumpDay(tester, DateTime(now.year, now.month, now.day), [
      _point('Running', now.subtract(const Duration(minutes: 10)), now.add(const Duration(minutes: 50))),
    ], past: true);
    expect(find.text('HEUTE'), findsNothing);
    expect(find.text('JETZT'), findsNothing);
  });
}
