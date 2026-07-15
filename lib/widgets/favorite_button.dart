import 'package:flutter/material.dart';

import '../services/prefs.dart';
import '../services/push.dart';

/// A star toggle bound to [Prefs] favorites for a given attraction
/// (`externalId`). Rebuilds reactively via the favorites [ValueNotifier] and
/// keeps the per-act push topic in sync.
class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key, required this.externalId, this.tooltip});

  final String externalId;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: Prefs.instance.favorites,
      builder: (context, favorites, _) {
        final isFav = favorites.contains(externalId);
        return IconButton(
          tooltip: tooltip ?? (isFav ? 'Aus Favoriten entfernen' : 'Zu Favoriten hinzufügen'),
          icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
          color: isFav ? Theme.of(context).colorScheme.primary : null,
          onPressed: () async {
            final nowFavorite = await Prefs.instance.toggleFavorite(externalId);
            await PushService.instance.setFavoriteTopic(externalId, nowFavorite);
          },
        );
      },
    );
  }
}
