import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-local persistence (onboarding flag, favorites, reminder switch) backed by
/// [SharedPreferences]. A single instance is created in `main.dart` via
/// [Prefs.init] and read through the [Prefs.instance] singleton, mirroring the
/// app's lightweight, no-state-library approach.
class Prefs {
  Prefs._(this._prefs);

  static const _kOnboardingComplete = 'onboarding_complete';
  static const _kFavorites = 'favorites'; // attraction externalIds
  static const _kRemindersEnabled = 'reminders_enabled';
  static const _kReminderLead = 'reminder_lead_minutes';

  static late Prefs instance;

  final SharedPreferences _prefs;

  /// Loads shared preferences and initializes [instance]. Call once at startup.
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    instance = Prefs._(prefs);
  }

  // --- Onboarding ---------------------------------------------------------

  bool get onboardingComplete => _prefs.getBool(_kOnboardingComplete) ?? false;

  Future<void> setOnboardingComplete() => _prefs.setBool(_kOnboardingComplete, true);

  // --- Favorites (per attraction externalId) ------------------------------

  /// The set of favorited attraction externalIds. Listen to [favorites] for
  /// reactive rebuilds when a favorite is toggled.
  late final ValueNotifier<Set<String>> favorites = ValueNotifier(_prefs.getStringList(_kFavorites)?.toSet() ?? <String>{});

  bool isFavorite(String externalId) => favorites.value.contains(externalId);

  /// Toggles [externalId] and persists. Returns the new favorite state.
  Future<bool> toggleFavorite(String externalId) async {
    final next = Set<String>.from(favorites.value);
    final nowFavorite = !next.remove(externalId);
    if (nowFavorite) next.add(externalId);
    favorites.value = next;
    await _prefs.setStringList(_kFavorites, next.toList());
    return nowFavorite;
  }

  // --- Reminders ----------------------------------------------------------

  /// Whether favorited acts get a local reminder before they start (on by
  /// default). Listened to by `NotificationService`.
  late final ValueNotifier<bool> remindersEnabled = ValueNotifier(_prefs.getBool(_kRemindersEnabled) ?? true);

  Future<void> setRemindersEnabled(bool on) async {
    remindersEnabled.value = on;
    await _prefs.setBool(_kRemindersEnabled, on);
  }

  /// The lead times a user can pick for reminders, in minutes.
  static const reminderLeadChoices = [5, 15, 30];
  static const _defaultReminderLead = 15;

  /// How many minutes before an act its reminder fires (one of
  /// [reminderLeadChoices], 15 by default). Listened to by `NotificationService`.
  late final ValueNotifier<int> reminderLeadMinutes = ValueNotifier(_validLead(_prefs.getInt(_kReminderLead)));

  Future<void> setReminderLeadMinutes(int minutes) async {
    final lead = _validLead(minutes);
    reminderLeadMinutes.value = lead;
    await _prefs.setInt(_kReminderLead, lead);
  }

  static int _validLead(int? minutes) => reminderLeadChoices.contains(minutes) ? minutes! : _defaultReminderLead;
}
