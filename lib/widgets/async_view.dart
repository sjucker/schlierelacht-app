import 'package:material_ui/material_ui.dart';

/// Renders the states of a [Future]: loading spinner, error with a retry
/// button, and the built data. Keeps screens free of repeated boilerplate.
///
/// When [future] is replaced (pull-to-refresh, retry), the data already shown
/// stays on screen until the new result arrives, so the list keeps its scroll
/// position instead of flashing a full-screen spinner. If that reload fails,
/// the old data stays too and a SnackBar says so; the error state appears
/// only when there is nothing to show at all.
class AsyncView<T> extends StatefulWidget {
  const AsyncView({super.key, required this.future, required this.onData, required this.onRetry});

  final Future<T> future;
  final Widget Function(BuildContext context, T data) onData;
  final VoidCallback onRetry;

  @override
  State<AsyncView<T>> createState() => _AsyncViewState<T>();
}

class _AsyncViewState<T> extends State<AsyncView<T>> {
  late T _last;
  bool _hasLast = false;
  Future<T>? _reportedFailure;

  void _reportFailedRefresh(Future<T> future) {
    if (identical(_reportedFailure, future)) return;
    _reportedFailure = future;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(const SnackBar(content: Text('Aktualisierung fehlgeschlagen.')));
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: widget.future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (!snapshot.hasError) {
            _last = snapshot.data as T;
            _hasLast = true;
          } else if (_hasLast) {
            _reportFailedRefresh(widget.future);
          } else {
            return _ErrorState(onRetry: widget.onRetry);
          }
        }
        if (!_hasLast) return const Center(child: CircularProgressIndicator());
        return widget.onData(context, _last);
      },
    );
  }
}

/// Completes when [future] does, success or failure — for a
/// `RefreshIndicator.onRefresh`, which should spin until the reload is over
/// but not rethrow (the [AsyncView] shows a failure itself).
Future<void> settled(Future<Object?> future) => future.then((_) {}, onError: (Object _) {});

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            const Text('Inhalt konnte nicht geladen werden.', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: onRetry, child: const Text('Erneut versuchen')),
          ],
        ),
      ),
    );
  }
}
