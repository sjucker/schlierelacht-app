// Offline fallback: successful GETs are cached, network failures serve the
// cached copy (with recomputed `past` flags), and the offline notifier follows.
import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:schlierelacht_app/api/api_cache.dart';
import 'package:schlierelacht_app/api/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiCache.offlineSince.value = null;
  });

  ApiClient online(String body, {int status = 200}) => ApiClient(client: MockClient((_) async => http.Response(body, status)));
  final offline = ApiClient(client: MockClient((_) async => throw const SocketException('no network')));

  test('serves the cached response when offline, and flags it', () async {
    expect(await online('[1,2]').getList('/api/v1/news'), [1, 2]);
    expect(ApiCache.offlineSince.value, isNull);

    expect(await offline.getList('/api/v1/news'), [1, 2]);
    expect(ApiCache.offlineSince.value, isNotNull);

    // Back online: the banner clears.
    await online('[3]').getList('/api/v1/news');
    expect(ApiCache.offlineSince.value, isNull);
  });

  test('falls back on a 5xx, but not on a 404', () async {
    await online('{"a":1}').getObject('/api/v1/ok');
    expect(await online('', status: 503).getObject('/api/v1/ok'), {'a': 1});
    expect(online('', status: 404).getObject('/api/v1/ok'), throwsA(isA<ApiException>()));
  });

  test('throws when offline and nothing is cached', () {
    expect(offline.getList('/api/v1/programm'), throwsA(isA<ApiException>()));
  });

  test('cache keys include the query', () async {
    await online('["food"]').getList('/api/v1/attraction?type=FOOD');
    expect(offline.getList('/api/v1/attraction'), throwsA(isA<ApiException>()));
    expect(await offline.getList('/api/v1/attraction?type=FOOD'), ['food']);
  });

  testWidgets('falls back when the backend does not answer in time', (tester) async {
    // testWidgets runs in fake time, so the 10 s timeout can be skipped over.
    await tester.runAsync(() => online('["saved"]').getList('/api/v1/news'));
    final hanging = ApiClient(client: MockClient((_) => Completer<http.Response>().future));

    List<dynamic>? result;
    unawaited(hanging.getList('/api/v1/news').then((r) => result = r));
    await tester.pump(ApiClient.requestTimeout - const Duration(seconds: 1));
    expect(result, isNull, reason: 'still waiting for the backend');

    await tester.pump(const Duration(seconds: 2));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero)); // let the cache read finish
    await tester.pump();
    expect(result, ['saved']);
  });

  test('the banner shows the oldest saved data on screen', () async {
    SharedPreferences.setMockInitialValues({
      'api_cache:/api/v1/news': '{"t":"2027-09-01T10:00:00.000","b":"[]"}',
      'api_cache:/api/v1/ok': '{"t":"2027-09-02T10:00:00.000","b":"{}"}',
    });
    await offline.getList('/api/v1/news');
    await offline.getObject('/api/v1/ok');
    expect(ApiCache.offlineSince.value, DateTime(2027, 9, 1, 10));
  });

  test('refreshPastFlags applies the backend rule with the device clock', () {
    Map<String, dynamic> entry(String from, {String? toDate, String? toTime}) => {'fromDate': from, 'toDate': toDate, 'toTime': toTime, 'past': false};
    final now = DateTime(2027, 9, 5, 22, 30);
    final json = [
      {'entry': entry('2027-09-04')}, // start only, day before: past
      {'entry': entry('2027-09-05')}, // start only, today: not yet
      {'entry': entry('2027-09-05', toDate: '2027-09-05', toTime: '22:00')}, // ended 22:00
      {'entry': entry('2027-09-05', toDate: '2027-09-05', toTime: '23:00:00')}, // still running
      {'entry': entry('2027-09-04', toDate: '2027-09-05')}, // ends with the day
    ];
    refreshPastFlags(json, now);
    expect([for (final p in json) (p['entry'] as Map)['past']], [true, false, true, false, false]);
  });
}
