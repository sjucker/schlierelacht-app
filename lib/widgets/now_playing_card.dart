import 'dart:async';

import 'package:flutter/material.dart';

import '../api/programm_api.dart';
import '../models/now_playing.dart';
import '../models/programm_point.dart';
import '../models/schedule.dart';
import '../screens/attraction_detail_screen.dart';
import '../utils/formatting.dart';
import 'programm_entry_tile.dart';

/// "Jetzt läuft" on the landing page: the acts on stage right now and the next
/// few (see [nowAndNext]). Re-evaluated every minute, the programm reloaded
/// when the app returns to the foreground (cache fallback included, so it
/// works offline). Takes no space when nothing is on or coming up soon — and
/// also while the programm loads or fails to.
class NowPlayingCard extends StatefulWidget {
  const NowPlayingCard({super.key});

  @override
  State<NowPlayingCard> createState() => _NowPlayingCardState();
}

class _NowPlayingCardState extends State<NowPlayingCard> {
  static const _tick = Duration(minutes: 1);

  List<ProgrammPoint> _points = const [];
  Timer? _timer;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(_tick, (_) => setState(() {}));
    _lifecycle = AppLifecycleListener(onResume: _load);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final points = await ProgrammApi().fetchProgramm();
      if (mounted) setState(() => _points = points);
    } catch (_) {
      // Nothing to show: the card simply stays hidden.
    }
  }

  void _open(ScheduleItem item) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => AttractionDetailScreen(externalId: item.attraction.externalId)));

  @override
  Widget build(BuildContext context) {
    final current = nowAndNext(_points, DateTime.now());
    if (current.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (current.now.isNotEmpty) ...[
              const _Heading('Jetzt läuft', live: true),
              for (final item in current.now) ProgrammEntryTile(item: item, onTap: () => _open(item), subtitle: _until(item)),
            ],
            if (current.next.isNotEmpty) ...[
              const _Heading('Als Nächstes'),
              for (final item in current.next) ProgrammEntryTile(item: item, onTap: () => _open(item)),
            ],
          ],
        ),
      ),
    );
  }

  /// "Hauptbühne · bis 22:00" when the end time is known.
  static String? _until(ScheduleItem item) {
    final end = formatTime(item.entry.toTime);
    return end.isEmpty ? null : '${item.entry.location.name} · bis $end';
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text, {this.live = false});

  final String text;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.secondaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (live) ...[Icon(Icons.circle, size: 10, color: theme.colorScheme.error), const SizedBox(width: 8)],
          Text(
            text.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.2, color: theme.colorScheme.onSecondaryContainer),
          ),
        ],
      ),
    );
  }
}
