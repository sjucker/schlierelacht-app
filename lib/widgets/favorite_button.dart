import 'package:flutter/material.dart';

import '../services/prefs.dart';
import '../services/push.dart';
import '../theme.dart';

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
        // Active = brand blue on light backgrounds (list rows), but logo yellow
        // where the surrounding icons are light (the blue app bar), where blue
        // would vanish.
        final ambient = IconTheme.of(context).color;
        final onDark = ambient != null && ThemeData.estimateBrightnessForColor(ambient) == Brightness.light;
        return IconButton(
          tooltip: tooltip ?? (isFav ? 'Aus Favoriten entfernen' : 'Zu Favoriten hinzufügen'),
          icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
          color: isFav ? (onDark ? FestColors.yellow : Theme.of(context).colorScheme.primary) : null,
          onPressed: () async {
            final nowFavorite = await Prefs.instance.toggleFavorite(externalId);
            await PushService.instance.setFavoriteTopic(externalId, nowFavorite);
          },
        );
      },
    );
  }
}
