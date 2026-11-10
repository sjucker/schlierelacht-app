// "Jetzt läuft": which programm entries count as running now and which as next.
import 'package:flutter_test/flutter_test.dart';
import 'package:schlierelacht_app/models/now_playing.dart';
import 'package:schlierelacht_app/models/programm_point.dart';

ProgrammPoint _point(String id, String fromDate, String? fromTime, {String? toDate, String? toTime}) => ProgrammPoint.fromJson({
  'attraction': {'externalId': id, 'name': id},
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
    'fromDate': fromDate,
    'fromTime': fromTime,
    'toDate': toDate,
    'toTime': toTime,
    'past': false,
  },
});

List<String> _ids(Iterable<dynamic> items) => [for (final i in items) i.attraction.externalId as String];

void main() {
  final now = DateTime(2027, 9, 3, 20, 30);

  test('running: started and not yet over, by start time', () {
    final result = nowAndNext([
      _point('late', '2027-09-03', '20:15', toTime: '21:00'),
      _point('early', '2027-09-03', '19:00', toTime: '22:00'),
      _point('over', '2027-09-03', '18:00', toTime: '20:30'),
    ], now);

    expect(_ids(result.now), ['early', 'late']);
    expect(result.next, isEmpty);
  });

  test('an end at or before the start runs past midnight', () {
    final result = nowAndNext([_point('night', '2027-09-03', '23:00', toTime: '02:00')], DateTime(2027, 9, 4, 1));
    expect(_ids(result.now), ['night']);
  });

  test('without an end time: until the end of toDate, else one hour', () {
    final result = nowAndNext([
      _point('multiDay', '2027-09-02', '10:00', toDate: '2027-09-03'),
      _point('oneHourAgo', '2027-09-03', '19:30'),
      _point('justStarted', '2027-09-03', '20:00'),
    ], now);

    expect(_ids(result.now), ['multiDay', 'justStarted']);
  });

  test('next: the first few starting within the window; all-day entries are left out', () {
    final result = nowAndNext([
      _point('d', '2027-09-04', '00:30'),
      _point('a', '2027-09-03', '21:00'),
      _point('c', '2027-09-03', '23:00'),
      _point('b', '2027-09-03', '22:00'),
      _point('tomorrowEvening', '2027-09-04', '18:00'),
      _point('allDay', '2027-09-03', null),
    ], now);

    expect(_ids(result.next), ['a', 'b', 'c'], reason: 'capped at 3, earliest first');
    expect(result.now, isEmpty);
  });

  test('empty before the festival and between festival days', () {
    final result = nowAndNext([_point('a', '2027-09-03', '18:00')], DateTime(2027, 6, 1));
    expect(result.isEmpty, isTrue);
  });
}
