import 'dart:async';

import 'package:flutter/foundation.dart';

/// Notifies once a minute, for labels that depend on the time of day (the
/// schedule's "HEUTE" and "Jetzt"). One shared timer that runs only while
/// something listens, instead of one per row.
class MinuteClock extends ChangeNotifier {
  Timer? _timer;

  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
    _timer ??= Timer.periodic(const Duration(minutes: 1), (_) => notifyListeners());
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (!hasListeners) {
      _timer?.cancel();
      _timer = null;
    }
  }
}

final MinuteClock minuteClock = MinuteClock();
