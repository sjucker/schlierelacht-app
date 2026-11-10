// The landing footer shows the installed version, for bug reports.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:schlierelacht_app/screens/landing_screen.dart';

PackageInfo _info(String version, String buildNumber) =>
    PackageInfo(appName: 'Schlierefäscht', packageName: 'ch.schlierelacht.schlierelacht_app', version: version, buildNumber: buildNumber);

void main() {
  setUpAll(() => initializeDateFormatting('de_CH'));

  test('label: version plus build number, if any', () {
    expect(appVersionLabel(_info('1.2.3', '45')), '1.2.3 (45)');
    expect(appVersionLabel(_info('1.2.3', '')), '1.2.3');
  });

  testWidgets('the landing footer shows it', (tester) async {
    PackageInfo.setMockInitialValues(
      appName: 'Schlierefäscht',
      packageName: 'ch.schlierelacht.schlierelacht_app',
      version: '1.2.3',
      buildNumber: '45',
      buildSignature: '',
    );
    await tester.pumpWidget(const MaterialApp(home: LandingScreen()));
    await tester.scrollUntilVisible(find.text('Version 1.2.3 (45)'), 300);
    expect(find.text('Version 1.2.3 (45)'), findsOneWidget);
  });
}
