import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../api/faq_api.dart';
import '../models/faq.dart';
import '../utils/external_links.dart';
import '../widgets/async_view.dart';

/// FAQ (app only): the questions grouped under their group headers, in the
/// backend's order; a tap expands the markdown answer. The search filters over
/// question + answer and shows the matches expanded.
class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key, this.api});

  /// For tests; defaults to a real [FaqApi].
  final FaqApi? api;

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  late final FaqApi _api = widget.api ?? FaqApi();
  late Future<List<FaqGroup>> _future;

  /// Owns the search text, so it survives the search bar being rebuilt
  /// (it is hidden while the list is empty).
  final _search = TextEditingController();
  String get _query => _search.text;

  @override
  void initState() {
    super.initState();
    _future = _api.fetchFaq();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _reload() => setState(() {
    _future = _api.fetchFaq();
  });

  /// Pull-to-refresh: the indicator spins until the new data is in, while
  /// the current list stays on screen (see [AsyncView]).
  Future<void> _refresh() {
    _reload();
    return settled(_future);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FAQ')),
      body: AsyncView<List<FaqGroup>>(
        future: _future,
        onRetry: _reload,
        onData: (context, all) {
          final searching = _query.trim().isNotEmpty;
          final groups = filterFaq(all, _query);
          return RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              slivers: [
                if (all.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: SearchBar(controller: _search, hintText: 'Frage oder Stichwort suchen…', leading: const Icon(Icons.search)),
                    ),
                  ),
                if (all.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(padding: EdgeInsets.all(24), child: Text('Im Moment sind keine Fragen erfasst.')),
                  )
                else if (groups.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(padding: EdgeInsets.all(24), child: Text('Keine Treffer.')),
                  )
                else
                  for (final group in groups) ...[
                    SliverToBoxAdapter(child: _GroupHeader(group.name)),
                    SliverList.builder(
                      itemCount: group.entries.length,
                      // The key includes the search state, so matches open
                      // when searching and close again when it is cleared.
                      itemBuilder: (context, i) => _Question(key: ValueKey('${group.entries[i].id}-$searching'), entry: group.entries[i], expanded: searching),
                    ),
                  ],
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// The groups with only the entries whose question or answer contains
/// [query] (case-insensitive); groups without a match are left out. An empty
/// query keeps everything.
@visibleForTesting
List<FaqGroup> filterFaq(List<FaqGroup> groups, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return groups;
  return [
    for (final group in groups)
      if (group.entries.where((e) => '${e.title}\n${e.content}'.toLowerCase().contains(q)).toList() case final matches when matches.isNotEmpty)
        FaqGroup(name: group.name, entries: matches),
  ];
}

/// A group name in the light-blue section style of the schedule's day headers.
class _GroupHeader extends StatelessWidget {
  const _GroupHeader(this.name);

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.secondaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(
        name.toUpperCase(),
        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.8, color: theme.colorScheme.primary),
      ),
    );
  }
}

class _Question extends StatelessWidget {
  const _Question({super.key, required this.entry, required this.expanded});

  final FaqEntry entry;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ExpansionTile(
      initiallyExpanded: expanded,
      title: Text(entry.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: const Border(),
      children: [MarkdownBody(data: entry.content, onTapLink: (_, href, _) => openUrl(href))],
    );
  }
}
