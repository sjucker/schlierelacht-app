import 'package:material_ui/material_ui.dart';

import '../services/geolocation.dart';
import '../services/notifications.dart';
import '../services/prefs.dart';
import '../services/push.dart';
import 'landing_screen.dart';

/// First-launch setup: a short, button-driven [PageView] that welcomes the
/// user and requests notification + location permissions. Completion is
/// persisted via [Prefs] so it only shows once. Swiping is disabled — users
/// advance with the buttons.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() => _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    _next();
  }

  /// One OS prompt covers push and the favorite reminders. The FCM request
  /// also registers the device; the local one still asks when Firebase isn't
  /// configured (and returns at once when the prompt was already answered).
  Future<void> _allowNotifications() async {
    await PushService.instance.requestAndRegister();
    await NotificationService.instance.requestPermission();
  }

  Future<void> _finish() async {
    await Prefs.instance.setOnboardingComplete();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LandingScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PageView(
          controller: _controller,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _OnboardingPage(
              icon: null,
              title: 'Willkommen am Schlierefäscht',
              body:
                  'Das Festival in deiner Tasche: Programm, Essen, Karte und mehr. '
                  'Wir richten die App in zwei kurzen Schritten für dich ein.',
              buttonLabel: 'Los geht\'s',
              busy: _busy,
              onPressed: _next,
            ),
            _OnboardingPage(
              icon: Icons.notifications_active_outlined,
              title: 'Bleib auf dem Laufenden',
              body:
                  'Erlaube Mitteilungen für Neuigkeiten und eine Erinnerung, '
                  'kurz bevor deine favorisierten Acts beginnen.',
              buttonLabel: 'Benachrichtigungen erlauben',
              secondaryLabel: 'Später',
              busy: _busy,
              onPressed: () => _run(_allowNotifications),
              onSecondary: _next,
            ),
            _OnboardingPage(
              icon: Icons.location_on_outlined,
              title: 'Finde dich zurecht',
              body:
                  'Mit deinem Standort zeigen wir dir auf der Karte, wie weit die '
                  'Bühnen und Stände entfernt sind.',
              buttonLabel: 'Standort erlauben',
              secondaryLabel: 'Später',
              busy: _busy,
              onPressed: () => _run(() => GeolocationService.instance.ensurePermission()),
              onSecondary: _next,
            ),
            _OnboardingPage(
              icon: Icons.celebration_outlined,
              title: 'Alles bereit!',
              body: 'Viel Spass am Schlierefäscht.',
              buttonLabel: 'App starten',
              busy: _busy,
              onPressed: _finish,
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.body,
    required this.buttonLabel,
    required this.busy,
    required this.onPressed,
    this.secondaryLabel,
    this.onSecondary,
  });

  final IconData? icon;
  final String title;
  final String body;
  final String buttonLabel;
  final String? secondaryLabel;
  final bool busy;
  final VoidCallback onPressed;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          if (icon == null) Image.asset('assets/logo.png', height: 160) else Icon(icon, size: 96, color: theme.colorScheme.primary),
          const SizedBox(height: 40),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Text(body, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
          const Spacer(),
          FilledButton(
            onPressed: busy ? null : onPressed,
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            child: busy ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(buttonLabel),
          ),
          if (secondaryLabel != null) ...[const SizedBox(height: 8), TextButton(onPressed: busy ? null : onSecondary, child: Text(secondaryLabel!))],
        ],
      ),
    );
  }
}
