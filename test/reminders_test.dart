// Planning of the local reminders before favorited acts: which entries get
// one, when (Swiss wall-clock time minus the lead), the text and tap target.
import 'package:flutter_test/flutter_test.dart';
import 'package:schlierelacht_app/models/programm_point.dart';
import 'package:schlierelacht_app/services/notifications.dart';
import 'package:timezone/data/latest_10y.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

ProgrammPoint _point(String id, String date, String? time) => ProgrammPoint.fromJson({
  'attraction': {'externalId': id, 'name': 'Act $id'},
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
    'fromDate': date,
    'fromTime': time,
    'past': false,
  },
});

void main() {
  late tz.Location zurich;
  late tz.TZDateTime now;

  setUpAll(() {
    tz_data.initializeTimeZones();
    zurich = tz.getLocation('Europe/Zurich');
  });

  setUp(() => now = tz.TZDateTime(zurich, 2027, 9, 3, 12));

  test('favorited entries with a start time get a reminder before it, earliest first', () {
    final planned = planReminders(
      [_point('B', '2027-09-04', '20:30'), _point('A', '2027-09-03', '18:00:00'), _point('C', '2027-09-03', '19:00')],
      {'A', 'B'},
      now,
      zurich,
    );

    expect(planned.map((r) => r.route), ['/programm/A', '/programm/B'], reason: 'C is not a favorite');
    expect(planned.first.at, tz.TZDateTime(zurich, 2027, 9, 3, 17, 45));
    expect(planned.first.title, 'Act A beginnt um 18:00');
    expect(planned.first.body, 'Hauptbühne');
  });

  test('no reminder for all-day entries or once the reminder time has passed', () {
    final planned = planReminders(
      [_point('A', '2027-09-03', null), _point('A', '2027-09-03', '12:10'), _point('A', '2027-09-02', '20:00'), _point('A', '2027-09-03', '12:16')],
      {'A'},
      now,
      zurich,
    );

    expect(planned.map((r) => r.at), [tz.TZDateTime(zurich, 2027, 9, 3, 12, 1)]);
  });

  test('capped below the iOS limit of pending notifications', () {
    final points = [for (var i = 0; i < 80; i++) _point('A', '2027-09-${(4 + i ~/ 10).toString().padLeft(2, '0')}', '${10 + i % 10}:00')];
    final planned = planReminders(points, {'A'}, now, zurich);

    expect(planned, hasLength(NotificationService.maxReminders));
    expect(planned.first.at, tz.TZDateTime(zurich, 2027, 9, 4, 9, 45));
  });

  test('the chosen lead time moves the reminder, and can drop one that is too close', () {
    final points = [_point('A', '2027-09-03', '12:20'), _point('A', '2027-09-03', '18:00')];

    expect(planReminders(points, {'A'}, now, zurich, lead: const Duration(minutes: 30)).map((r) => r.at), [
      tz.TZDateTime(zurich, 2027, 9, 3, 17, 30),
    ], reason: '12:20 minus 30 min is already past at 12:00');
    expect(planReminders(points, {'A'}, now, zurich, lead: const Duration(minutes: 5)).map((r) => r.at), [
      tz.TZDateTime(zurich, 2027, 9, 3, 12, 15),
      tz.TZDateTime(zurich, 2027, 9, 3, 17, 55),
    ]);
  });
}
