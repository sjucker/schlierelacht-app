import 'package:flutter/material.dart';

import '../api/event_api.dart';
import '../models/programm_point.dart';
import '../widgets/async_view.dart';
import '../widgets/intro_text.dart';
import '../widgets/schedule_list.dart';
import 'attraction_detail_screen.dart';

/// Sponsor events and business gatherings around the festival (website:
/// `wirtschaft/index.vue`), from `GET /api/v1/event`. Same upcoming /
/// "Vergangene" layout as the Programm.
class WirtschaftScreen extends StatefulWidget {
  const WirtschaftScreen({super.key});

  static const title = 'Wirtschaft & Gewerbe';

  @override
  State<WirtschaftScreen> createState() => _WirtschaftScreenState();
}

class _WirtschaftScreenState extends State<WirtschaftScreen> {
  final _api = EventApi();
  late Future<List<ProgrammPoint>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.fetchEvents();
  }

  void _reload() => setState(() => _future = _api.fetchEvents());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(WirtschaftScreen.title)),
      body: AsyncView<List<ProgrammPoint>>(
        future: _future,
        onRetry: _reload,
        onData: (context, points) => RefreshIndicator(
          onRefresh: () async => _reload(),
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(
                child: IntroText([
                  TextSpan(
                    text:
                        'Vor und am Schlierefäscht 2027 finden diverse '
                        'interessante Sponsoren-Events und Wirtschafts-Anlässe '
                        'statt. Wir wünschen viele spannende Networking '
                        'Gelegenheiten und Begegnungen.',
                  ),
                  TextSpan(
                    text: 'Sponsoring Team Schlierelacht 2027',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ]),
              ),
              if (points.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(padding: EdgeInsets.all(24), child: Text('Zurzeit sind keine Anlässe aufgeschaltet.')),
                )
              else
                ...scheduleSlivers(
                  points: points,
                  showFavorite: false,
                  onTapItem: (item) => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AttractionDetailScreen(externalId: item.attraction.externalId, title: WirtschaftScreen.title),
                    ),
                  ),
                ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
            ],
          ),
        ),
      ),
    );
  }
}
