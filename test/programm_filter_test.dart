// The Programm screen's filters: act search, date and stage, combinable.
import 'package:flutter_test/flutter_test.dart';
import 'package:schlierelacht_app/models/programm_point.dart';
import 'package:schlierelacht_app/screens/programm_screen.dart';

ProgrammPoint _point(String name, String date, String stageId) => ProgrammPoint.fromJson({
  'attraction': {'externalId': name, 'name': name},
  'entry': {
    'location': {
      'externalId': stageId,
      'type': 'STAGE',
      'name': 'Bühne $stageId',
      'latitude': 47.39,
      'longitude': 8.44,
      'googleMapsUrl': 'https://maps.google.com/?q=1',
      'showInFestplan': true,
    },
    'fromDate': date,
    'fromTime': '20:00',
    'past': false,
  },
});

void main() {
  final points = [_point('Lola Band', '2027-09-03', 'S1'), _point('Patent Brass', '2027-09-03', 'S2'), _point('Lovely Days', '2027-09-04', 'S1')];
  List<String> names(List<ProgrammPoint> result) => [for (final p in result) p.attraction.name];

  test('no filter keeps everything', () {
    expect(names(filterProgramm(points)), names(points));
  });

  test('the search is case-insensitive, trimmed and matches inside the name', () {
    expect(names(filterProgramm(points, query: '  LO ')), ['Lola Band', 'Lovely Days']);
    expect(names(filterProgramm(points, query: 'bras')), ['Patent Brass']);
  });

  test('date and stage filter, also combined with the search', () {
    expect(names(filterProgramm(points, date: DateTime(2027, 9, 3))), ['Lola Band', 'Patent Brass']);
    expect(names(filterProgramm(points, stageId: 'S1')), ['Lola Band', 'Lovely Days']);
    expect(names(filterProgramm(points, query: 'lo', date: DateTime(2027, 9, 4), stageId: 'S1')), ['Lovely Days']);
    expect(filterProgramm(points, query: 'bras', stageId: 'S1'), isEmpty);
  });
}
