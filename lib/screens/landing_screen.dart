import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../config.dart';
import '../theme.dart';
import '../utils/external_links.dart';
import '../widgets/crash_test_dialog.dart';
import '../widgets/message_card.dart';
import '../widgets/now_playing_card.dart';
import 'faq_screen.dart';
import 'favorites_screen.dart';
import 'festplan_screen.dart';
import 'gastro_screen.dart';
// import 'info_screen.dart'; // tile hidden for now, see _cards
import 'jahrgangstreffen_screen.dart';
import 'news_list_screen.dart';
import 'notification_settings_screen.dart';
import 'problem_report_screen.dart';
import 'programm_screen.dart';
// import 'social_media_screen.dart'; // tile hidden for now, see _cards
import 'sponsoring_screen.dart';

/// App home (the website's home page + its navigation): the festival logo,
/// the most important active Meldung (app-only, see [MessageCard]), the
/// countdown to the festival start, the "free entry" note, a grid linking to
/// every section, and a footer with the social links and a Datenschutz link to the website.
///
/// The sections follow the website's nav order; Favoriten, FAQ and Problem melden are app-only
/// additions.
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  static final _cards = <_NavCard>[
    _NavCard('News', Icons.newspaper_outlined, () => _titled('News', const NewsListScreen())),
    _NavCard('Programm', Icons.calendar_month_outlined, () => const ProgrammScreen()),
    _NavCard('Favoriten', Icons.favorite_outline, () => const FavoritesScreen()),
    _NavCard('Jahrgangs-\ntreffen', Icons.groups_outlined, () => const JahrgangstreffenScreen()),
    _NavCard('Festplan', Icons.map_outlined, () => const FestplanScreen()),
    _NavCard('Gastro', Icons.restaurant_outlined, () => const GastroScreen()),
    _NavCard('Sponsoren', Icons.handshake_outlined, () => const SponsoringScreen()),
    // Hidden for now; the screens stay (Über uns is still reachable via the /info deep link).
    // _NavCard('Social Media', Icons.forum_outlined, () => const SocialMediaScreen()),
    // _NavCard('Über uns', Icons.info_outline, () => const InfoScreen()),
    _NavCard('FAQ', Icons.help_outline, () => const FaqScreen()),
    _NavCard('Problem\nmelden', Icons.report_problem_outlined, () => const ProblemReportScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(padding: const EdgeInsets.fromLTRB(24, 32, 24, 16), child: Image.asset('assets/logo.png', height: 260)),
            ),
            // The most important active Meldung (title only); hidden when none.
            const SliverToBoxAdapter(child: MessageCard()),
            const SliverToBoxAdapter(child: _FestBanner()),
            // What is on stage now and next; hidden outside festival days.
            const SliverToBoxAdapter(child: NowPlayingCard()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.0,
                ),
                delegate: SliverChildBuilderDelegate((context, i) => _CardTile(card: _cards[i]), childCount: _cards.length),
              ),
            ),
            const SliverToBoxAdapter(child: _Footer()),
          ],
        ),
      ),
    );
  }
}

/// Wraps a body-only screen (News) in a titled Scaffold so it works as a
/// pushed route with an app bar + back button.
Widget _titled(String title, Widget body) => _TitledPage(title: title, body: body);

class _TitledPage extends StatelessWidget {
  const _TitledPage({required this.title, required this.body});

  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: body,
  );
}

/// Countdown to [festStart] (hidden once the festival has begun) and the
/// "Freier Eintritt zu allen Konzerten" note — the website's home page.
class _FestBanner extends StatefulWidget {
  const _FestBanner();

  @override
  State<_FestBanner> createState() => _FestBannerState();
}

class _FestBannerState extends State<_FestBanner> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (_now.isBefore(festStart)) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _now = DateTime.now());
        if (!_now.isBefore(festStart)) _timer?.cancel();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = festStart.difference(_now);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        color: FestColors.yellow,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              if (!remaining.isNegative) ...[
                Text(
                  '10 unvergessliche Tage in Schlieren. Es dauert nur noch:',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(color: FestColors.blue),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _CountdownUnit('${remaining.inDays}', 'Tage'),
                    const _Colon(),
                    _CountdownUnit(_two(remaining.inHours % 24), 'Std'),
                    const _Colon(),
                    _CountdownUnit(_two(remaining.inMinutes % 60), 'Min'),
                  ],
                ),
                Divider(color: FestColors.blue.withValues(alpha: 0.25), height: 20),
              ],
              Text(
                'Freier Eintritt zu allen Konzerten',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(color: FestColors.blue, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _two(int v) => v.toString().padLeft(2, '0');
}

class _CountdownUnit extends StatelessWidget {
  const _CountdownUnit(this.value, this.label);

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: FestColors.blue,
            fontWeight: FontWeight.bold,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text(label.toUpperCase(), style: theme.textTheme.labelSmall?.copyWith(color: FestColors.blue)),
      ],
    );
  }
}

class _Colon extends StatelessWidget {
  const _Colon();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(10, 0, 10, 18),
    child: Text(
      ':',
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: FestColors.blue, fontWeight: FontWeight.bold),
    ),
  );
}

/// Social links, the Mitteilungen settings and a Datenschutz link to the
/// website (the website's footer, without copyright and Impressum).
class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: [
          Text(
            'SOCIAL MEDIA',
            style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 1.5, color: theme.colorScheme.primary),
          ),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              TextButton.icon(onPressed: () => openUrl(facebookUrl), icon: const Icon(Icons.facebook), label: const Text('Facebook')),
              TextButton.icon(onPressed: () => openUrl(instagramUrl), icon: const Icon(Icons.camera_alt_outlined), label: const Text('Instagram')),
              TextButton.icon(onPressed: () => openUrl(linkedinUrl), icon: const Icon(Icons.work_outline), label: const Text('LinkedIn')),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const NotificationSettingsScreen())),
                child: const Text('Mitteilungen'),
              ),
              // Required by the app stores; opens the website's page in the browser.
              TextButton(onPressed: () => openUrl(datenschutzUrl), child: const Text('Datenschutz')),
            ],
          ),
          const _AppVersion(),
        ],
      ),
    );
  }
}

/// "Version 1.0.0 (1)" — the installed version and build number (from
/// `pubspec.yaml`), so a bug report can say which build it is about. Shows
/// nothing until the platform has answered, or if it can't. A long press
/// opens the hidden crash-reporting test ([showCrashTestDialog]).
class _AppVersion extends StatelessWidget {
  const _AppVersion();

  static final Future<PackageInfo> _info = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<PackageInfo>(
      future: _info,
      builder: (context, snapshot) {
        final info = snapshot.data;
        if (info == null) return const SizedBox.shrink();
        // Long press: hidden crash-reporting test (see crash_test_dialog.dart).
        return GestureDetector(
          onLongPress: () => showCrashTestDialog(context),
          child: Text('Version ${appVersionLabel(info)}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
        );
      },
    );
  }
}

/// `1.0.0 (1)`: the version name, plus the build number when there is one.
@visibleForTesting
String appVersionLabel(PackageInfo info) => info.buildNumber.isEmpty ? info.version : '${info.version} (${info.buildNumber})';

class _NavCard {
  const _NavCard(this.label, this.icon, this.pageBuilder);

  final String label;
  final IconData icon;
  final Widget Function() pageBuilder;
}

/// A home tile: logo blue with a white icon and label.
class _CardTile extends StatelessWidget {
  const _CardTile({required this.card});

  final _NavCard card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: FestColors.blue,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => card.pageBuilder())),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(card.icon, size: 28, color: Colors.white),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                card.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
