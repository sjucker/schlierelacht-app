import 'dart:async';

import 'package:flutter/material.dart';

import '../config.dart';
import '../utils/external_links.dart';
import 'favorites_screen.dart';
import 'festplan_screen.dart';
import 'gastro_screen.dart';
import 'info_screen.dart';
import 'jahrgangstreffen_screen.dart';
import 'news_list_screen.dart';
import 'programm_screen.dart';
import 'sponsoring_screen.dart';

const Color _festYellow = Color(0xFFFFF03F);

/// App home (the website's home page + its navigation): the festival logo, the
/// countdown to the festival start, the "free entry" note, a grid linking to
/// every section, and a footer with the social links.
///
/// The sections follow the website's nav order; Favoriten is an app-only
/// addition.
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
    _NavCard('Über uns', Icons.info_outline, () => const InfoScreen()),
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
            const SliverToBoxAdapter(child: _FestBanner()),
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
        color: _festYellow,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              if (!remaining.isNegative) ...[
                Text(
                  '10 unvergessliche Tage in Schlieren. Es dauert nur noch:',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.black),
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
                const Divider(color: Colors.black26, height: 20),
              ],
              Text(
                'Freier Eintritt zu allen Konzerten',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(color: Colors.black, fontWeight: FontWeight.bold),
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
          style: theme.textTheme.headlineMedium?.copyWith(color: Colors.black, fontWeight: FontWeight.bold, fontFeatures: const [FontFeature.tabularFigures()]),
        ),
        Text(label.toUpperCase(), style: theme.textTheme.labelSmall?.copyWith(color: Colors.black)),
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
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.black, fontWeight: FontWeight.bold),
    ),
  );
}

/// Social links (the website's footer, without copyright and legal pages).
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
        ],
      ),
    );
  }
}

class _NavCard {
  const _NavCard(this.label, this.icon, this.pageBuilder);

  final String label;
  final IconData icon;
  final Widget Function() pageBuilder;
}

class _CardTile extends StatelessWidget {
  const _CardTile({required this.card});

  final _NavCard card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => card.pageBuilder())),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(card.icon, size: 28, color: theme.colorScheme.primary),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                card.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
