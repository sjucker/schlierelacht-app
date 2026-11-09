import 'package:flutter/material.dart';

import '../api/programm_api.dart';
import '../models/programm_point.dart';
import '../utils/formatting.dart';
import '../widgets/async_view.dart';
import '../widgets/schedule_list.dart';
import 'attraction_detail_screen.dart';

/// The festival programm (website: `programm/index.vue`): a
/// free-text search over the act name plus date and stage filters (all
/// resettable), then the schedule split into upcoming and "Vergangene".
/// Each row carries a favorite toggle.
class ProgrammScreen extends StatefulWidget {
  const ProgrammScreen({super.key});

  @override
  State<ProgrammScreen> createState() => _ProgrammScreenState();
}

class _ProgrammScreenState extends State<ProgrammScreen> {
  final _api = ProgrammApi();
  late Future<List<ProgrammPoint>> _future;

  final _search = TextEditingController();
  DateTime? _date;
  String? _stageId;

  @override
  void initState() {
    super.initState();
    _future = _api.fetchProgramm();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _reload() => setState(() {
    _future = _api.fetchProgramm();
  });

  bool get _hasFilter => _search.text.isNotEmpty || _date != null || _stageId != null;

  void _resetFilters() => setState(() {
    _search.clear();
    _date = null;
    _stageId = null;
  });

  List<ProgrammPoint> _filter(List<ProgrammPoint> points) {
    final term = _search.text.trim().toLowerCase();
    return points.where((p) {
      if (_date != null && p.entry.fromDate != _date) return false;
      if (_stageId != null && p.entry.location.externalId != _stageId) {
        return false;
      }
      if (term.isNotEmpty && !p.attraction.name.toLowerCase().contains(term)) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Programm')),
      body: AsyncView<List<ProgrammPoint>>(
        future: _future,
        onRetry: _reload,
        onData: (context, points) {
          final dates = points.map((p) => p.entry.fromDate).toSet().toList()..sort();
          final stages = <String, String>{for (final p in points) p.entry.location.externalId: p.entry.location.name}.entries.toList()
            ..sort((a, b) => a.value.compareTo(b.value));
          final filtered = _filter(points);

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _filters(dates, stages)),
                if (filtered.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(points.isEmpty ? 'Das Programm folgt in Kürze.' : 'Keine Einträge gefunden.'),
                    ),
                  )
                else
                  ...scheduleSlivers(
                    points: filtered,
                    onTapItem: (item) =>
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => AttractionDetailScreen(externalId: item.attraction.externalId))),
                  ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _filters(List<DateTime> dates, List<MapEntry<String, String>> stages) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        children: [
          SearchBar(
            controller: _search,
            hintText: 'Act suchen…',
            leading: const Icon(Icons.search),
            trailing: [if (_hasFilter) IconButton(tooltip: 'Filter zurücksetzen', icon: const Icon(Icons.close), onPressed: _resetFilters)],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _Select<DateTime>(
                  hint: 'Datum',
                  value: _date,
                  items: {for (final d in dates) d: formatGermanDate(d)},
                  onChanged: (v) => setState(() => _date = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Select<String>(
                  hint: 'Bühne',
                  value: _stageId,
                  items: {for (final s in stages) s.key: s.value},
                  onChanged: (v) => setState(() => _stageId = v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A compact outlined dropdown with an "all" entry (null) on top.
class _Select<T> extends StatelessWidget {
  const _Select({required this.hint, required this.value, required this.items, required this.onChanged});

  final String hint;
  final T? value;
  final Map<T, String> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T?>(
          isExpanded: true,
          value: items.containsKey(value) ? value : null,
          hint: Text(hint),
          items: [
            DropdownMenuItem<T?>(value: null, child: Text('Alle ($hint)')),
            for (final e in items.entries)
              DropdownMenuItem<T?>(
                value: e.key,
                child: Text(e.value, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
