// openDeepLink: what a tapped push or reminder does with its route.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schlierelacht_app/utils/deep_links.dart';

class _Pushes extends NavigatorObserver {
  final names = <String?>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => names.add(route.settings.name);
}

void main() {
  late _Pushes pushes;

  Widget app() => MaterialApp(navigatorKey: navigatorKey, navigatorObservers: [pushes], home: const SizedBox());

  setUp(() => pushes = _Pushes());

  testWidgets('a route the app can show is pushed on top', (tester) async {
    await tester.pumpWidget(app());
    openDeepLink('news');
    await tester.pump();
    expect(pushes.names, ['/', 'news']);
  });

  testWidgets('anything else is ignored', (tester) async {
    await tester.pumpWidget(app());
    openDeepLink('/datenschutz');
    openDeepLink(null);
    await tester.pump();
    expect(pushes.names, ['/']);
  });

  testWidgets('a tap that launched the app opens its screen after the first frame', (tester) async {
    openDeepLink('/news/7'); // no navigator yet
    await tester.pumpWidget(app());
    await tester.pump();
    expect(pushes.names, ['/', '/news/7']);
  });
}
