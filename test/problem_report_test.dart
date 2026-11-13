// "Problem melden": the multipart request the backend expects, and the form's
// required fields.
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:schlierelacht_app/api/api_client.dart';
import 'package:schlierelacht_app/api/problem_report_api.dart';
import 'package:schlierelacht_app/screens/problem_report_screen.dart';
import 'package:schlierelacht_app/services/prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Captures the request; answers with [status].
MockClient _recorder(List<http.Request> requests, {int status = 200}) => MockClient((request) async {
  requests.add(request);
  return http.Response('', status);
});

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Prefs.init();
  });

  group('ProblemReportApi', () {
    test('sends the report as JSON part and the photo as image part', () async {
      final requests = <http.Request>[];
      final api = ProblemReportApi(client: ApiClient(client: _recorder(requests)));

      await api.send(name: 'Hans', description: 'WC voll', latitude: 47.4, longitude: 8.45, photo: Uint8List.fromList([1, 2, 3]), photoName: 'wc.jpg');

      final request = requests.single;
      expect(request.method, 'POST');
      expect(request.url.path, '/api/v1/problem-report');
      expect(request.headers['content-type'], startsWith('multipart/form-data'));
      final body = latin1.decode(request.bodyBytes);
      expect(body, contains('name="report"'));
      expect(body, contains('content-type: application/json'));
      expect(body, contains('{"name":"Hans","description":"WC voll","latitude":47.4,"longitude":8.45}'));
      expect(body, contains('name="photo"; filename="wc.jpg"'));
      expect(body, contains('content-type: image/jpeg'));
    });

    test('omits phone, position and photo when not given', () async {
      final requests = <http.Request>[];
      await ProblemReportApi(client: ApiClient(client: _recorder(requests))).send(name: 'Anna', description: 'Kabel');

      final body = latin1.decode(requests.single.bodyBytes);
      expect(body, contains('{"name":"Anna","description":"Kabel"}'));
      expect(body, isNot(contains('name="photo"')));
    });

    test('throws on an error status', () async {
      final api = ProblemReportApi(client: ApiClient(client: _recorder([], status: 503)));

      expect(api.send(name: 'Hans', description: 'WC voll'), throwsA(isA<ApiException>()));
    });
  });

  group('ProblemReportScreen', () {
    Future<List<http.Request>> pumpScreen(WidgetTester tester, {int status = 200}) async {
      final requests = <http.Request>[];
      await tester.pumpWidget(
        MaterialApp(
          home: ProblemReportScreen(
            api: ProblemReportApi(
              client: ApiClient(client: _recorder(requests, status: status)),
            ),
          ),
        ),
      );
      return requests;
    }

    Finder field(String label) => find.widgetWithText(TextFormField, label);

    Future<void> tapSend(WidgetTester tester) async {
      await tester.ensureVisible(find.text('Senden'));
      await tester.tap(find.text('Senden'));
      await tester.pumpAndSettle();
    }

    testWidgets('name and description are required', (tester) async {
      final requests = await pumpScreen(tester);

      await tapSend(tester);

      expect(find.text('Bitte gib deinen Namen an.'), findsOneWidget);
      expect(find.text('Bitte beschreibe das Problem.'), findsOneWidget);
      expect(requests, isEmpty);
    });

    testWidgets('sends and remembers the name', (tester) async {
      final requests = await pumpScreen(tester);

      await tester.enterText(field('Name *'), ' Hans ');
      await tester.enterText(field('Beschreibung *'), 'WC voll');
      await tapSend(tester);

      expect(requests, hasLength(1));
      expect(latin1.decode(requests.single.bodyBytes), contains('{"name":"Hans","description":"WC voll"}'));
      expect(Prefs.instance.reporterName, 'Hans');
    });

    testWidgets('keeps the input when sending fails', (tester) async {
      await pumpScreen(tester, status: 503);

      await tester.enterText(field('Name *'), 'Hans');
      await tester.enterText(field('Beschreibung *'), 'WC voll');
      await tapSend(tester);

      expect(find.text('Senden fehlgeschlagen – bitte später erneut versuchen.'), findsOneWidget);
      expect(find.text('WC voll'), findsOneWidget);
    });
  });

  group('camera access', () {
    // A valid 1×1 PNG, so Image.memory can decode the preview.
    final photo = (bytes: base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII='), name: 'wc.png');

    /// A camera that is denied until [allowed] is set.
    ({List<ImageSource> calls, void Function() allow, PhotoPicker picker}) camera() {
      final calls = <ImageSource>[];
      var allowed = false;
      return (
        calls: calls,
        allow: () => allowed = true,
        picker: (source) async {
          calls.add(source);
          if (!allowed) throw PlatformException(code: 'camera_access_denied');
          return photo;
        },
      );
    }

    Future<void> tapCamera(WidgetTester tester) async {
      await tester.ensureVisible(find.text('Foto aufnehmen'));
      await tester.tap(find.text('Foto aufnehmen'));
      await tester.pumpAndSettle();
    }

    testWidgets('Android: denied access can be asked for again right away', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final cam = camera();
      await tester.pumpWidget(MaterialApp(home: ProblemReportScreen(pickPhoto: cam.picker)));

      await tapCamera(tester);
      expect(find.text('Zugriff auf die Kamera'), findsOneWidget);

      cam.allow();
      await tester.tap(find.text('Erneut versuchen'));
      await tester.pumpAndSettle();

      expect(cam.calls, hasLength(2));
      expect(find.byType(Image), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('iOS: opens the settings, keeps the input and reopens the camera on return', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final cam = camera();
      var settingsOpened = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: ProblemReportScreen(
            pickPhoto: cam.picker,
            openSettings: () async {
              settingsOpened++;
              return true;
            },
          ),
        ),
      );
      await tester.enterText(find.widgetWithText(TextFormField, 'Beschreibung *'), 'Kabel offen');

      await tapCamera(tester);
      expect(find.text('Erneut versuchen'), findsNothing, reason: 'iOS asks only once');
      await tester.tap(find.text('Einstellungen öffnen'));
      await tester.pumpAndSettle();

      expect(settingsOpened, 1);
      expect(Prefs.instance.problemReportDraft, contains('Kabel offen'));

      cam.allow();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(cam.calls, hasLength(2));
      expect(find.byType(Image), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('a draft saved before the settings comes back once', (tester) async {
      await Prefs.instance.setProblemReportDraft('{"name":"Anna","phone":"","description":"WC voll","sendLocation":true}');

      await tester.pumpWidget(const MaterialApp(home: ProblemReportScreen()));

      expect(find.text('Anna'), findsOneWidget);
      expect(find.text('WC voll'), findsOneWidget);
      expect(Prefs.instance.problemReportDraft, isNull);
    });
  });
}
