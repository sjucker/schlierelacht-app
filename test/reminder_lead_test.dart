// The reminder lead time: stored in Prefs, picked on the Mitteilungen screen.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schlierelacht_app/screens/notification_settings_screen.dart';
import 'package:schlierelacht_app/services/prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> prefs(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    await Prefs.init();
  }

  test('15 minutes by default, and for a value that is not a choice', () async {
    await prefs({});
    expect(Prefs.instance.reminderLeadMinutes.value, 15);

    await prefs({'reminder_lead_minutes': 7});
    expect(Prefs.instance.reminderLeadMinutes.value, 15);
  });

  test('a picked lead time is stored', () async {
    await prefs({});
    await Prefs.instance.setReminderLeadMinutes(30);
    expect(Prefs.instance.reminderLeadMinutes.value, 30);
    expect((await SharedPreferences.getInstance()).getInt('reminder_lead_minutes'), 30);
  });

  testWidgets('the Mitteilungen screen picks it, and greys it out while reminders are off', (tester) async {
    await prefs({});
    await tester.pumpWidget(const MaterialApp(home: NotificationSettingsScreen()));
    await tester.pump();
    expect(find.text('15 Minuten bevor ein favorisierter Act beginnt'), findsOneWidget);

    await tester.tap(find.text('5 Min.'));
    await tester.pump();
    expect(Prefs.instance.reminderLeadMinutes.value, 5);
    expect(find.text('5 Minuten bevor ein favorisierter Act beginnt'), findsOneWidget);
    expect(find.textContaining('ein paar Minuten später'), findsOneWidget, reason: 'short lead: drift hint');

    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tester.tap(find.text('30 Min.'));
    await tester.pump();
    expect(Prefs.instance.reminderLeadMinutes.value, 5, reason: 'disabled while reminders are off');
  });
}
