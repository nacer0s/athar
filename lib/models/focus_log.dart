// ═══════════════════════════════════════════════════════════════════
//  ATHAR (أثر) — lib/models/focus_log.dart
//
//  Schema rules (NEVER break after first install):
//  • typeId = 0 — never change
//  • HiveField indices — never reorder or reuse
//  • New non-nullable fields → next fresh index + defaultValue
//  • Removed fields → retire the index forever (leave a comment)
// ═══════════════════════════════════════════════════════════════════

import 'package:hive/hive.dart';

part 'focus_log.g.dart';

// ───────────────────────────────────────────────────────────────────
//  MODEL
// ───────────────────────────────────────────────────────────────────

@HiveType(typeId: 0)
class FocusLog extends HiveObject {
  /// Field 0 — User's micro-journal note (non-empty, trimmed).
  @HiveField(0)
  late String taskNote;

  /// Field 1 — Session length in minutes (e.g. 25, 45, 60).
  @HiveField(1)
  late int durationMinutes;

  /// Field 2 — UTC-aware DateTime of when the session was logged.
  /// Always store UTC; convert to local only for display.
  @HiveField(2)
  late DateTime timestamp;

  /// Field 3 — Star / Bookmark toggle.
  /// defaultValue: false keeps old records safe.
  @HiveField(3, defaultValue: false)
  late bool isStarred;

  /// Field 4 — Optional mood score (1–5). Reserved for v1.2+.
  /// Nullable — old records without this field return null.
  @HiveField(4)
  int? moodScore;

  // ─── INDEX GRAVEYARD ──────────────────────────────────────────
  // Retired indices: (none yet)
  // If you remove a field, add its index here so it is never reused.

  // ───────────────────────────────────────────────────────────────
  //  CONSTRUCTOR
  // ───────────────────────────────────────────────────────────────

  FocusLog({
    required this.taskNote,
    required this.durationMinutes,
    required this.timestamp,
    this.isStarred = false,
    this.moodScore,
  });

  // ───────────────────────────────────────────────────────────────
  //  COPY-WITH
  // ───────────────────────────────────────────────────────────────

  FocusLog copyWith({
    String? taskNote,
    int? durationMinutes,
    DateTime? timestamp,
    bool? isStarred,
    int? moodScore,
  }) =>
      FocusLog(
        taskNote: taskNote ?? this.taskNote,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        timestamp: timestamp ?? this.timestamp,
        isStarred: isStarred ?? this.isStarred,
        moodScore: moodScore ?? this.moodScore,
      );

  // ───────────────────────────────────────────────────────────────
  //  SERIALIZATION — used by CSV export in settings_screen
  // ───────────────────────────────────────────────────────────────

  /// Converts to a plain map. Safe for JSON encoding and CSV export.
  // ✅ FIX: Map → Map<String, dynamic>
  Map<String, dynamic> toMap() => {
        'taskNote': taskNote,
        'durationMinutes': durationMinutes,
        'timestamp': timestamp.toIso8601String(),
        'isStarred': isStarred,
        'moodScore': moodScore,
      };

  /// Reconstructs a FocusLog from a [toMap] result.
  /// Does NOT restore the Hive key — use only for import/migration.
  // ✅ FIX: Map → Map<String, dynamic>
  factory FocusLog.fromMap(Map<String, dynamic> map) => FocusLog(
        taskNote: map['taskNote'] as String,
        durationMinutes: map['durationMinutes'] as int,
        timestamp: DateTime.parse(map['timestamp'] as String),
        isStarred: (map['isStarred'] as bool?) ?? false,
        moodScore: map['moodScore'] as int?,
      );

  // ───────────────────────────────────────────────────────────────
  //  COMPUTED PROPERTIES
  // ───────────────────────────────────────────────────────────────

  /// Session length expressed as fractional hours (90 min → 1.5).
  double get durationHours => durationMinutes / 60.0;

  /// True when this session was logged today (local clock).
  bool get isToday {
    final now = DateTime.now();
    final local = timestamp.toLocal();
    return local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
  }

  /// True when this session falls within the current Mon–Sun week.
  bool get isThisWeek {
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1)); // Monday 00:00
    final weekEnd = weekStart.add(const Duration(days: 7)); // next Monday 00:00
    final local = timestamp.toLocal();
    return !local.isBefore(weekStart) && local.isBefore(weekEnd);
  }

  // ───────────────────────────────────────────────────────────────
  //  STAR TOGGLE
  // ───────────────────────────────────────────────────────────────

  /// Flips [isStarred] and persists the change to Hive in one call.
  // ✅ FIX: Future → Future<void>
  Future<void> toggleStar() async {
    isStarred = !isStarred;
    await save(); // HiveObject.save() — writes only this entry
  }

  // ───────────────────────────────────────────────────────────────
  //  EQUALITY & DEBUG
  // ───────────────────────────────────────────────────────────────

  @override
  String toString() => 'FocusLog(task: "$taskNote", '
      'duration: ${durationMinutes}min, '
      'at: ${timestamp.toLocal()}, '
      'starred: $isStarred)';
}
