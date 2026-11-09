// Parsing of the hand-written models against JSON shaped like the backend DTOs
// (see schlierelacht-website/shared/types/rest.ts), and the schedule split.
import 'package:flutter_test/flutter_test.dart';
import 'package:schlierelacht_app/models/attraction.dart';
import 'package:schlierelacht_app/models/location.dart';
import 'package:schlierelacht_app/models/meetup.dart';
import 'package:schlierelacht_app/models/ok.dart';
import 'package:schlierelacht_app/models/programm_point.dart';
import 'package:schlierelacht_app/models/schedule.dart';
import 'package:schlierelacht_app/models/sponsoring.dart';

Map<String, dynamic> _location({String id = 'L1', String type = 'STAGE', bool showInFestplan = true}) => {
  'externalId': id,
  'type': type,
  'name': 'Hauptbühne',
  'latitude': 47.39,
  'longitude': 8.44,
  'googleMapsUrl': 'https://maps.google.com/?q=1',
  'showInFestplan': showInFestplan,
};

Map<String, dynamic> _point(String name, String date, String? time, {bool past = false}) => {
  'attraction': {'externalId': name, 'name': name},
  'entry': {'location': _location(), 'fromDate': date, 'fromTime': time, 'past': past},
};

void main() {
  test('Location parses showInFestplan and EVENT_LOCATION', () {
    final loc = Location.fromJson(_location(type: 'EVENT_LOCATION'));
    expect(loc.type, LocationType.eventLocation);
    expect(loc.showInFestplan, isTrue);
  });

  test('Attraction parses files and programm past flag', () {
    final a = Attraction.fromJson({
      'externalId': 'A1',
      'name': 'Band',
      'description': '',
      'images': [],
      'programm': [
        {'location': _location(), 'fromDate': '2027-09-03', 'past': true},
      ],
      'files': [
        {'id': 7, 'filename': 'rider.pdf', 'filetype': 'application/pdf', 'description': 'Rider', 'filesize': 2048},
      ],
    });
    expect(a.programm.single.past, isTrue);
    expect(a.files.single.id, 7);
    expect(a.files.single.filesize, 2048);
  });

  test('OK, meetup and sponsoring types parse', () {
    final ok = Ok.fromJson({
      'members': [
        {'name': 'Max', 'role': 'Präsident'},
      ],
      'teamMembers': [
        {'name': 'Eva', 'team': 'SICHERHEIT', 'email': 'eva@x.ch'},
      ],
    });
    expect(ok.members.single.email, isNull);
    expect(ok.teamMembers.single.team, OkTeam.sicherheit);

    final entry = MeetupEntry.fromJson({'firstname': 'A', 'lastname': 'B', 'jahrgang': 'BORN_1984_1988'});
    expect(entry.jahrgang, MeetupJahrgang.born1984To1988);

    final type = SponsoringTypeInfo.fromJson({'type': 'GOENNER', 'description': 'Gönner'});
    expect(type.type, SponsoringType.goenner);
    // Declaration order mirrors the website's TYPE_ORDER.
    expect(SponsoringType.values.first, SponsoringType.organisation);

    // Free-text URLs: only absolute http(s) links survive (Gönner come with "").
    String? url(String? value) => Sponsoring.fromJson({'type': 'GOENNER', 'name': 'X', 'url': value}).url;
    expect(url(''), isNull);
    expect(url(null), isNull);
    expect(url('arcanus ag'), isNull);
    expect(url('https://abaum.ch'), 'https://abaum.ch');
  });

  test('buildSchedule orders chronologically, or most recent first', () {
    final points = [
      _point('B', '2027-09-04', '18:00'),
      _point('A', '2027-09-03', '20:00'),
      _point('C', '2027-09-03', '17:00'),
    ].map(ProgrammPoint.fromJson).toList();

    final asc = buildSchedule(points);
    expect(asc.map((d) => d.date.day), [3, 4]);
    expect(asc.first.items.map((i) => i.attraction.name), ['C', 'A']);

    final desc = buildSchedule(points, mostRecentFirst: true);
    expect(desc.map((d) => d.date.day), [4, 3]);
    expect(desc.last.items.map((i) => i.attraction.name), ['A', 'C']);
  });
}
