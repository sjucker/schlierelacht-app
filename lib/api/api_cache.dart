import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Offline fallback for the public API: the last successful response body of
/// every GET, keyed by its path (incl. query), in [SharedPreferences]. The
/// whole API is well under 1 MB, so this stays small.
///
/// [ApiClient] writes every successful GET here and reads from it when the
/// network fails; [OfflineWarmup] fills it in the background so screens work
/// offline even if they were never opened.
abstract final class ApiCache {
  static const _prefix = 'api_cache:';

  /// When the data currently shown was saved — set while responses come from
  /// the cache, null again as soon as a request reaches the backend. Drives
  /// the app-wide offline banner.
  static final ValueNotifier<DateTime?> offlineSince = ValueNotifier(null);

  static Future<void> put(String path, String body) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix$path', jsonEncode({'t': DateTime.now().toIso8601String(), 'b': body}));
  }

  /// The cached body for [path] and when it was saved, or null if none.
  static Future<({DateTime savedAt, String body})?> get(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$path');
    if (raw == null) return null;
    try {
      final entry = jsonDecode(raw) as Map<String, dynamic>;
      return (savedAt: DateTime.parse(entry['t'] as String), body: entry['b'] as String);
    } catch (_) {
      return null; // unreadable entry: behave as if nothing was cached
    }
  }
}

/// Recomputes every programm entry's `past` flag in decoded API JSON against
/// [now]. The backend sets `past` at request time, so a cached response would
/// keep a stale "upcoming vs. Vergangene" split; this applies the backend's
/// rule (`ProgrammEntryDTO.isPast`) with the device clock instead:
/// with a `toDate`, past once that end has passed (`toTime`, or else the start
/// of the following day); with only a `fromDate`, past from the following day.
void refreshPastFlags(Object? json, DateTime now) {
  if (json is List) {
    for (final e in json) {
      refreshPastFlags(e, now);
    }
  } else if (json is Map<String, dynamic>) {
    final from = json['fromDate'];
    if (from is String && json.containsKey('past')) {
      json['past'] = _isPast(from, json['toDate'] as String?, json['toTime'] as String?, now);
    }
    for (final v in json.values) {
      refreshPastFlags(v, now);
    }
  }
}

bool _isPast(String fromDate, String? toDate, String? toTime, DateTime now) {
  final DateTime end;
  if (toDate != null) {
    final day = DateTime.parse(toDate);
    final t = toTime?.split(':');
    end = t != null && t.length >= 2 ? DateTime(day.year, day.month, day.day, int.parse(t[0]), int.parse(t[1])) : DateTime(day.year, day.month, day.day + 1);
  } else {
    final day = DateTime.parse(fromDate);
    end = DateTime(day.year, day.month, day.day + 1);
  }
  return !now.isBefore(end);
}
