import 'package:flutter/material.dart';

import 'favorites_screen.dart';
import 'gastro_screen.dart';
import 'karte_screen.dart';
import 'locations_screen.dart';
import 'news_list_screen.dart';
import 'programm_screen.dart';
import 'sponsoring_screen.dart';

/// App home: the festival logo over a grid of cards linking to every section.
/// Replaces the old News/Programm bottom-nav shell as the app's entry point.
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  static final _cards = <_NavCard>[
    _NavCard('News', Icons.newspaper_outlined, () => _titled('News', const NewsListScreen())),
    _NavCard('Programm', Icons.calendar_month_outlined, () => _titled('Programm', const ProgrammScreen())),
    _NavCard('Gastro', Icons.restaurant_outlined, () => const GastroScreen()),
    _NavCard('Favoriten', Icons.favorite_outline, () => const FavoritesScreen()),
    _NavCard('Karte', Icons.map_outlined, () => const KarteScreen()),
    _NavCard('Sponsoren', Icons.handshake_outlined, () => const SponsoringScreen()),
    _NavCard('Locations', Icons.place_outlined, () => const LocationsScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Column(children: [Image.asset('assets/logo.png', height: 300)]),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
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
          ],
        ),
      ),
    );
  }
}

/// Wraps a body-only screen (News/Programm) in a titled Scaffold so it works as
/// a pushed route with an app bar + back button.
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
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
