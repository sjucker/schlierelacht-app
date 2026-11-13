import 'package:material_ui/material_ui.dart';

import '../services/notifications.dart';
import '../services/prefs.dart';
import '../services/push.dart';

/// "Mitteilungen": whether the OS lets the app notify (with a way to allow it
/// later — onboarding asks only once), and the switch for reminders before
/// favorited acts. Reached from the landing footer and the Favoriten app bar.
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool? _permitted;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _refresh();
    // Coming back from the system settings: pick up the new state, and
    // register for push if it was just allowed there.
    _lifecycle = AppLifecycleListener(onResume: _refresh);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final permitted = await NotificationService.instance.isPermitted();
    if (permitted) await PushService.instance.registerIfPermitted();
    if (mounted) setState(() => _permitted = permitted);
  }

  /// Prompts if the OS still allows it; once declined, only the system
  /// settings can turn notifications back on.
  Future<void> _allow() async {
    await PushService.instance.requestAndRegister();
    final permitted = await NotificationService.instance.requestPermission();
    if (!permitted) await NotificationService.instance.openSettings();
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final permitted = _permitted;
    return Scaffold(
      appBar: AppBar(title: const Text('Mitteilungen')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          if (permitted == null)
            const ListTile(title: Text('Wird geprüft…'))
          else
            ListTile(
              leading: Icon(
                permitted ? Icons.notifications_active_outlined : Icons.notifications_off_outlined,
                color: permitted ? theme.colorScheme.primary : theme.colorScheme.error,
              ),
              title: Text(permitted ? 'Mitteilungen sind erlaubt' : 'Mitteilungen sind ausgeschaltet'),
              subtitle: Text(
                permitted ? 'Du erhältst News und wichtige Ankündigungen.' : 'Du verpasst News, Ankündigungen und Erinnerungen an deine Favoriten.',
              ),
              trailing: permitted ? null : FilledButton(onPressed: _allow, child: const Text('Erlauben')),
            ),
          const Divider(),
          ListenableBuilder(
            listenable: Listenable.merge([Prefs.instance.remindersEnabled, Prefs.instance.reminderLeadMinutes]),
            builder: (context, _) {
              final enabled = Prefs.instance.remindersEnabled.value;
              final lead = Prefs.instance.reminderLeadMinutes.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.alarm_outlined),
                    title: const Text('Erinnerung an Favoriten'),
                    subtitle: Text('$lead Minuten bevor ein favorisierter Act beginnt'),
                    value: enabled,
                    onChanged: Prefs.instance.setRemindersEnabled,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(72, 4, 16, 8),
                    child: SegmentedButton<int>(
                      segments: [for (final m in Prefs.reminderLeadChoices) ButtonSegment(value: m, label: Text('$m Min.'))],
                      selected: {lead},
                      showSelectedIcon: false,
                      // Greyed out while reminders are off, but keeps the choice.
                      onSelectionChanged: enabled ? (s) => Prefs.instance.setReminderLeadMinutes(s.single) : null,
                    ),
                  ),
                  if (enabled && lead < 15)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(72, 0, 16, 8),
                      child: Text(
                        'Das Handy stellt Erinnerungen manchmal ein paar Minuten später zu.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
