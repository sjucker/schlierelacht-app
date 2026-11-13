import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

import '../api/api_cache.dart';
import '../theme.dart';

/// Wraps the whole app (`MaterialApp.builder`). While the app shows cached data
/// because the backend is unreachable, a strip below every screen says so:
/// "Offline – gespeicherter Stand vom 09.11., 14:32". It disappears as soon as
/// a request gets through again.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DateTime?>(
      valueListenable: ApiCache.offlineSince,
      builder: (context, since, _) {
        if (since == null) return child;
        final stand = DateFormat('dd.MM., HH:mm', 'de_CH').format(since);
        return Column(
          children: [
            // The strip owns the bottom inset now; the screen above must not
            // reserve it a second time.
            Expanded(
              child: MediaQuery.removePadding(context: context, removeBottom: true, child: child),
            ),
            Material(
              color: FestColors.yellow,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_off_outlined, size: 18, color: FestColors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Offline – gespeicherter Stand vom $stand',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: FestColors.blue, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
