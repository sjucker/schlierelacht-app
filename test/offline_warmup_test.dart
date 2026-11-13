// The warm-up loads every endpoint on its own: a failing request yields null
// for that request only, so the rest of the warm-up still runs.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:schlierelacht_app/services/offline_warmup.dart';

void main() {
  test('a failing request yields null instead of throwing', () async {
    expect(await OfflineWarmup.loadOrNull<int>(() async => throw const SocketException('down')), isNull);
  });

  test('a successful request yields its value', () async {
    expect(await OfflineWarmup.loadOrNull(() async => 42), 42);
  });

  test('one failing endpoint does not stop the others', () async {
    final results = await Future.wait<Object?>([
      OfflineWarmup.loadOrNull<List<int>>(() async => throw const SocketException('404 on an old backend')),
      OfflineWarmup.loadOrNull(() async => 'ok'),
      OfflineWarmup.loadOrNull<int>(() async => throw StateError('bad json')),
      OfflineWarmup.loadOrNull(() async => 7),
    ]);
    expect(results, [null, 'ok', null, 7]);
  });
}
