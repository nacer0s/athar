// ═══════════════════════════════════════════════════════════════════
//  ATHAR (أثر) — lib/app_state.dart
//  Single ChangeNotifier managing ALL app state:
//    1. Locale        (AR ↔ EN, persisted)
//    2. ThemeMode     (System / Light / Dark, persisted)
//    3. Focus Timer   (Idle → Running → Paused → Completed)
//    4. Settings      (duration, notifications, persisted)
//    5. Hive CRUD     (save / delete / star / clear logs)
//    6. Stats         (computed from Hive box — no duplication)
// ═══════════════════════════════════════════════════════════════════

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'models/focus_log.dart';

// ───────────────────────────────────────────────────────────────────
//  TIMER STATE ENUM
// ───────────────────────────────────────────────────────────────────

enum TimerStatus {
  idle, // timer shows full duration, no tick
  running, // counting down
  paused, // remaining time preserved, no tick
  completed, // reached 00:00 — prompts user to log
}

// ───────────────────────────────────────────────────────────────────
//  PREFERENCE KEYS
// ───────────────────────────────────────────────────────────────────

class _PrefKey {
  static const locale = 'locale';
  static const themeMode = 'themeMode';
  static const focusDuration = 'focusDuration';
  static const notifyOnComplete = 'notifyOnComplete';
  static const dailyReminder = 'dailyReminder';
  static const vibrateOnComplete = 'vibrateOnComplete';
}

// ───────────────────────────────────────────────────────────────────
//  APP STATE
// ───────────────────────────────────────────────────────────────────

class AppState extends ChangeNotifier {
  // ═══════════════════════════════════════════════════════════════
  //  INIT
  // ═══════════════════════════════════════════════════════════════

  Future<void> init() async {
    // Guard: open the prefs box here too so tests and hot-restart
    // never hit a closed-box crash even if main() races.
    if (!Hive.isBoxOpen('prefs')) {
      await Hive.openBox<dynamic>('prefs');
    }

    final p = _prefs;

    _locale = Locale(
      p.get(_PrefKey.locale, defaultValue: 'en') as String,
    );

    _themeMode =
        ThemeMode.values[p.get(_PrefKey.themeMode, defaultValue: 0) as int];

    _focusDurationMinutes = p.get(
      _PrefKey.focusDuration,
      defaultValue: _kDefaultDuration,
    ) as int;

    _remainingSeconds = _focusDurationMinutes * 60;
    _notifyOnComplete =
        p.get(_PrefKey.notifyOnComplete, defaultValue: false) as bool;
    _dailyReminder = p.get(_PrefKey.dailyReminder, defaultValue: false) as bool;
    _vibrateOnComplete =
        p.get(_PrefKey.vibrateOnComplete, defaultValue: false) as bool;
  }

  // ── Preferences box ───────────────────────────────────────────
  // ✅ FIX: typed as Box<dynamic> — matches openBox<dynamic>('prefs')
  //    in main.dart. Must use the SAME name string on both sides.
  Box<dynamic> get _prefs {
    assert(
      Hive.isBoxOpen('prefs'),
      '[AppState] Hive box "prefs" is not open. '
      'Ensure main() calls await Hive.openBox("prefs") before runApp().',
    );
    return Hive.box<dynamic>('prefs');
  }

  // ═══════════════════════════════════════════════════════════════
  //  SECTION 1 — LOCALE
  // ═══════════════════════════════════════════════════════════════

  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  void toggleLocale() {
    _locale =
        _locale.languageCode == 'en' ? const Locale('ar') : const Locale('en');
    _prefs.put(_PrefKey.locale, _locale.languageCode);
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  //  SECTION 2 — THEME
  // ═══════════════════════════════════════════════════════════════

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    _prefs.put(_PrefKey.themeMode, mode.index);
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  //  SECTION 3 — FOCUS TIMER
  // ═══════════════════════════════════════════════════════════════

  static const int _kDefaultDuration = 25;

  int _focusDurationMinutes = _kDefaultDuration;
  int _remainingSeconds = _kDefaultDuration * 60;
  TimerStatus _status = TimerStatus.idle;
  Timer? _ticker;

  int get focusDurationMinutes => _focusDurationMinutes;
  int get remainingSeconds => _remainingSeconds;
  TimerStatus get status => _status;

  String get formattedTime {
    final m = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double get progress {
    final total = _focusDurationMinutes * 60;
    if (total == 0) return 0.0;
    return 1.0 - (_remainingSeconds / total);
  }

  void setFocusDuration(int minutes) {
    assert(minutes > 0 && minutes <= 120, 'Duration must be 1–120 min');
    if (_status != TimerStatus.idle) return;
    _focusDurationMinutes = minutes;
    _remainingSeconds = minutes * 60;
    _prefs.put(_PrefKey.focusDuration, minutes);
    notifyListeners();
  }

  void startTimer() {
    if (_status != TimerStatus.idle && _status != TimerStatus.paused) return;
    _status = TimerStatus.running;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _ticker?.cancel();
        _ticker = null;
        _status = TimerStatus.completed;
        notifyListeners();
      }
    });
    notifyListeners();
  }

  void pauseTimer() {
    if (_status != TimerStatus.running) return;
    _ticker?.cancel();
    _ticker = null;
    _status = TimerStatus.paused;
    notifyListeners();
  }

  void resetTimer() {
    _ticker?.cancel();
    _ticker = null;
    _status = TimerStatus.idle;
    _remainingSeconds = _focusDurationMinutes * 60;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  //  SECTION 4 — NOTIFICATION & VIBE SETTINGS
  // ═══════════════════════════════════════════════════════════════

  bool _notifyOnComplete = false;
  bool _dailyReminder = false;
  bool _vibrateOnComplete = false;

  bool get notifyOnComplete => _notifyOnComplete;
  bool get dailyReminder => _dailyReminder;
  bool get vibrateOnComplete => _vibrateOnComplete;

  void setNotifyOnComplete(bool v) {
    _notifyOnComplete = v;
    _prefs.put(_PrefKey.notifyOnComplete, v);
    notifyListeners();
  }

  void setDailyReminder(bool v) {
    _dailyReminder = v;
    _prefs.put(_PrefKey.dailyReminder, v);
    notifyListeners();
  }

  void setVibrateOnComplete(bool v) {
    _vibrateOnComplete = v;
    _prefs.put(_PrefKey.vibrateOnComplete, v);
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  //  SECTION 5 — HIVE CRUD (Focus Logs)
  // ═══════════════════════════════════════════════════════════════

  // ✅ FIX: was Box (raw/dynamic) — must be Box<FocusLog> so that
  //    .values, .fold(), and all CRUD calls are properly typed.
  //    Without the generic, every l.durationMinutes access is dynamic
  //    and Dart emits implicit-dynamic warnings; worse, fold() can
  //    silently return the wrong type at runtime.
  Box<FocusLog> get _box => Hive.box<FocusLog>('focus_logs');

  // ✅ FIX: was List (raw) — typed as List<FocusLog>
  List<FocusLog> get logs => _box.values.toList().reversed.toList();

  int get totalSessions => _box.length;
  // ✅ FIX: fold typed as fold<int> — prevents dynamic arithmetic
  int get totalMinutes =>
      _box.values.fold<int>(0, (s, l) => s + l.durationMinutes);
  double get totalHours => totalMinutes / 60.0;
  int get avgSessionMinutes =>
      totalSessions == 0 ? 0 : (totalMinutes / totalSessions).round();

  // ✅ FIX: return type was List (raw) — now List<int>
  List<int> minutesPerDay({int days = 7}) {
    final now = DateTime.now();
    return List.generate(days, (i) {
      final day = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: (days - 1) - i));

      return _box.values.where((log) {
        final local = log.timestamp.toLocal();
        final logDay = DateTime(local.year, local.month, local.day);
        return logDay == day;
      })
          // ✅ FIX: fold typed as fold<int>
          .fold<int>(0, (s, l) => s + l.durationMinutes);
    });
  }

  // ✅ FIX: return type was Future (raw) — now Future<void>
  Future<void> saveLog(
    String taskNote, {
    bool isStarred = false,
  }) async {
    final trimmed = taskNote.trim();
    if (trimmed.isEmpty) return;

    await _box.add(
      FocusLog(
        taskNote: trimmed,
        durationMinutes: _focusDurationMinutes,
        timestamp: DateTime.now().toUtc(),
        isStarred: isStarred,
      ),
    );

    resetTimer(); // resets + notifies — no extra notifyListeners() needed
  }

  // ✅ FIX: return type was Future (raw) — now Future<FocusLog?>
  Future<FocusLog?> deleteLog(int reversedIndex) async {
    final all = _box.values.toList();
    if (reversedIndex < 0 || reversedIndex >= all.length) return null;

    final actualIndex = all.length - 1 - reversedIndex;
    final deleted = all[actualIndex];
    await deleted.delete(); // HiveObject.delete() — no key lookup needed
    notifyListeners();
    return deleted;
  }

  // ✅ FIX: return type was Future (raw) — now Future<void>
  Future<void> restoreLog(FocusLog log) async {
    await _box.add(log);
    notifyListeners();
  }

  // ✅ FIX: return type was Future (raw) — now Future<void>
  Future<void> clearAllLogs() async {
    await _box.clear();
    notifyListeners();
  }

  // ✅ FIX: return type was Future (raw) — now Future<void>
  Future<void> toggleStar(int reversedIndex) async {
    final all = _box.values.toList();
    if (reversedIndex < 0 || reversedIndex >= all.length) return;

    final actualIndex = all.length - 1 - reversedIndex;
    await all[actualIndex].toggleStar();
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  //  SECTION 6 — DISPOSE
  // ═══════════════════════════════════════════════════════════════

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
