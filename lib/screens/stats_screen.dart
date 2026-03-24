// ═══════════════════════════════════════════════════════════════════
//  ATHAR (أثر) — lib/screens/stats_screen.dart
//
//  UX highlights:
//  • Hero stat cards with animated count-up on entry
//  • 7-day bar chart (CustomPainter — no external dependency)
//  • 28-day activity heatmap grid
//  • Streak tracker (current + longest)
//  • Best session highlight card
//  • Time-of-day distribution ring (morning/afternoon/evening/night)
//  • Animated entry with staggered sections
//  • Full RTL / LTR support
//  • Rich empty state
// ═══════════════════════════════════════════════════════════════════

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../l10n/strings.dart';
import '../models/focus_log.dart';
import '../widgets/adaptive_scaffold.dart';

// ═══════════════════════════════════════════════════════════════════
//  STATS SCREEN
// ═══════════════════════════════════════════════════════════════════

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  // ✅ FIX: State → State<StatsScreen>
  State<StatsScreen> createState() => _StatsScreenState();
}

// ✅ FIX: State → State<StatsScreen>
class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryCtrl;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  // ✅ FIX: Animation → Animation<double>
  Animation<double> _stagger(double start, double end) => CurvedAnimation(
        parent: _entryCtrl,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );

  @override
  Widget build(BuildContext context) {
    // ✅ FIX: context.watch() → context.watch<AppState>()
    final state = context.watch<AppState>();
    final isAR = S.isRTL(context);
    final logs = state.logs; // newest-first

    return AdaptiveScaffold(
      title: S.of(context, 'stats_title'),
      body: logs.isEmpty
          ? _EmptyState(isAR: isAR)
          : _StatsBody(
              state: state,
              logs: logs,
              isAR: isAR,
              entryCtrl: _entryCtrl,
              stagger: _stagger,
            ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  STATS BODY
// ═══════════════════════════════════════════════════════════════════

class _StatsBody extends StatelessWidget {
  final AppState state;
  // ✅ FIX: List → List<FocusLog>
  final List<FocusLog> logs;
  final bool isAR;
  final AnimationController entryCtrl;
  // ✅ FIX: Animation Function → Animation<double> Function
  final Animation<double> Function(double, double) stagger;

  const _StatsBody({
    required this.state,
    required this.logs,
    required this.isAR,
    required this.entryCtrl,
    required this.stagger,
  });

  @override
  Widget build(BuildContext context) {
    final weekData = state.minutesPerDay(days: 7);
    final heatData = state.minutesPerDay(days: 28);
    final streaks = _computeStreaks(logs);
    final bestLog = _bestSession(logs);
    final todFracs = _timeOfDayFractions(logs);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      children: [
        // ── 1. Hero stat cards ──────────────────────────────────
        _FadeSlide(
          animation: stagger(0.0, 0.35),
          child: _HeroCards(state: state, isAR: isAR),
        ),
        const SizedBox(height: 22),

        // ── 2. Weekly bar chart ─────────────────────────────────
        _FadeSlide(
          animation: stagger(0.12, 0.45),
          child: _SectionCard(
            title: S.of(context, 'stats_weekly_chart'),
            child: _WeeklyBarChart(minutesPerDay: weekData, isAR: isAR),
          ),
        ),
        const SizedBox(height: 16),

        // ── 3. Streak cards ─────────────────────────────────────
        _FadeSlide(
          animation: stagger(0.22, 0.55),
          child: _StreakRow(
            current: streaks.$1,
            longest: streaks.$2,
            isAR: isAR,
          ),
        ),
        const SizedBox(height: 16),

        // ── 4. Activity heatmap ─────────────────────────────────
        _FadeSlide(
          animation: stagger(0.32, 0.65),
          child: _SectionCard(
            title: S.of(context, 'stats_heatmap'),
            child: _ActivityHeatmap(minutesPerDay: heatData, isAR: isAR),
          ),
        ),
        const SizedBox(height: 16),

        // ── 5. Time-of-day ring ─────────────────────────────────
        _FadeSlide(
          animation: stagger(0.42, 0.72),
          child: _SectionCard(
            title: S.of(context, 'stats_time_of_day'),
            child: _TimeOfDayChart(fractions: todFracs, isAR: isAR),
          ),
        ),
        const SizedBox(height: 16),

        // ── 6. Best session ─────────────────────────────────────
        if (bestLog != null)
          _FadeSlide(
            animation: stagger(0.52, 0.82),
            child: _BestSessionCard(log: bestLog, isAR: isAR),
          ),
      ],
    );
  }

  // ── Streak computation ─────────────────────────────────────────
  // Returns (currentStreak, longestStreak) in days
  // ✅ FIX: List → List<FocusLog>
  (int, int) _computeStreaks(List<FocusLog> logs) {
    if (logs.isEmpty) return (0, 0);

    // ✅ FIX: {} (raw Set literal) → <DateTime>{} (typed Set literal)
    final days = <DateTime>{};
    for (final l in logs) {
      final loc = l.timestamp.toLocal();
      days.add(DateTime(loc.year, loc.month, loc.day));
    }

    final sorted = days.toList()
      ..sort((a, b) => b.compareTo(a)); // newest first

    final today = DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);
    final yesterday = todayDay.subtract(const Duration(days: 1));

    // Current streak
    int current = 0;
    DateTime check = sorted.first == todayDay || sorted.first == yesterday
        ? sorted.first
        : DateTime(0);

    if (check != DateTime(0)) {
      for (final d in sorted) {
        if (d == check) {
          current++;
          check = check.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }
    }

    // Longest streak
    int longest = 1, run = 1;
    for (int i = 1; i < sorted.length; i++) {
      final diff = sorted[i - 1].difference(sorted[i]).inDays;
      if (diff == 1) {
        run++;
        if (run > longest) longest = run;
      } else {
        run = 1;
      }
    }

    return (current, longest);
  }

  // ✅ FIX: List → List<FocusLog>
  FocusLog? _bestSession(List<FocusLog> logs) {
    if (logs.isEmpty) return null;
    return logs
        .reduce((a, b) => a.durationMinutes >= b.durationMinutes ? a : b);
  }

  // ✅ FIX: List logs → List<FocusLog> logs, return List → List<double>
  List<double> _timeOfDayFractions(List<FocusLog> logs) {
    if (logs.isEmpty) return [0.25, 0.25, 0.25, 0.25];
    // 0=morn(5-12), 1=aftn(12-17), 2=eve(17-21), 3=night
    final counts = [0, 0, 0, 0];
    for (final l in logs) {
      final h = l.timestamp.toLocal().hour;
      if (h >= 5 && h < 12)
        counts[0]++;
      else if (h >= 12 && h < 17)
        counts[1]++;
      else if (h >= 17 && h < 21)
        counts[2]++;
      else
        counts[3]++;
    }
    final total = logs.length.toDouble();
    return counts.map((c) => c / total).toList();
  }
}

// ═══════════════════════════════════════════════════════════════════
//  FADE + SLIDE ENTRY WRAPPER
// ═══════════════════════════════════════════════════════════════════

class _FadeSlide extends StatelessWidget {
  // ✅ FIX: Animation → Animation<double>
  final Animation<double> animation;
  final Widget child;

  const _FadeSlide({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, ch) => Opacity(
        opacity: animation.value,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - animation.value)),
          child: ch,
        ),
      ),
      child: child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SECTION CARD
// ═══════════════════════════════════════════════════════════════════

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  HERO STAT CARDS
// ═══════════════════════════════════════════════════════════════════

class _HeroCards extends StatelessWidget {
  final AppState state;
  final bool isAR;

  const _HeroCards({required this.state, required this.isAR});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final cards = [
      _CardData(
        icon: Icons.check_circle_rounded,
        color: cs.primary,
        value: '${state.totalSessions}',
        label: S.of(context, 'stat_sessions'),
        sub: isAR ? 'إجمالي الجلسات' : 'All time',
      ),
      _CardData(
        icon: Icons.schedule_rounded,
        color: Colors.teal.shade600,
        value: state.totalHours.toStringAsFixed(1),
        label: S.of(context, 'stat_hours'),
        sub: isAR ? 'ساعة إجمالية' : 'Total hours',
      ),
      _CardData(
        icon: Icons.trending_up_rounded,
        color: Colors.deepPurple.shade400,
        value: '${state.avgSessionMinutes}',
        label: isAR ? 'د / جلسة' : 'min / avg',
        sub: isAR ? 'متوسط الجلسة' : 'Avg session',
      ),
      _CardData(
        icon: Icons.star_rounded,
        color: Colors.amber.shade600,
        value: '${state.logs.where((l) => l.isStarred).length}',
        label: S.of(context, 'stat_starred'),
        sub: isAR ? 'جلسات مميزة' : 'Starred',
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: cards.map((c) => _HeroCard(data: c)).toList(),
    );
  }
}

class _CardData {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final String sub;

  const _CardData({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    required this.sub,
  });
}

class _HeroCard extends StatelessWidget {
  final _CardData data;
  const _HeroCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(data.icon, color: data.color, size: 17),
              ),
              const Spacer(),
              Text(
                data.sub,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: cs.outline),
              ),
            ],
          ),
          const Spacer(),
          Text(
            data.value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                  height: 1.0,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            data.label,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: cs.outline),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  WEEKLY BAR CHART
// ═══════════════════════════════════════════════════════════════════

class _WeeklyBarChart extends StatefulWidget {
  // ✅ FIX: List → List<int>
  final List<int> minutesPerDay; // 7 values, index 0 = oldest
  final bool isAR;

  const _WeeklyBarChart({
    required this.minutesPerDay,
    required this.isAR,
  });

  @override
  State<_WeeklyBarChart> createState() => _WeeklyBarChartState();
}

class _WeeklyBarChartState extends State<_WeeklyBarChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _barCtrl;
  // ✅ FIX: Animation → Animation<double>
  late final Animation<double> _barAnim;

  @override
  void initState() {
    super.initState();
    _barCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _barAnim = CurvedAnimation(parent: _barCtrl, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _barCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final locale = widget.isAR ? 'ar' : 'en';
    final maxVal = widget.minutesPerDay.fold(0, max).toDouble();

    return Column(
      children: [
        SizedBox(
          height: 140,
          child: AnimatedBuilder(
            animation: _barAnim,
            builder: (_, __) => Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final mins = widget.minutesPerDay[i];
                final frac = maxVal == 0 ? 0.0 : mins / maxVal;
                final isToday = i == 6;
                final dayDate = now.subtract(Duration(days: 6 - i));
                final dayLabel = DateFormat('E', locale).format(dayDate);
                final barColor =
                    isToday ? cs.primary : cs.primary.withValues(alpha: 0.45);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (mins > 0)
                          Text(
                            mins >= 60
                                ? '${(mins / 60).toStringAsFixed(1)}h'
                                : '${mins}m',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: isToday ? cs.primary : cs.outline,
                                  fontWeight: isToday
                                      ? FontWeight.w700
                                      : FontWeight.normal,
                                  fontSize: 9,
                                ),
                          ),
                        const SizedBox(height: 3),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          height: (100 * frac * _barAnim.value)
                              .clamp(mins > 0 ? 4.0 : 2.0, 100.0),
                          decoration: BoxDecoration(
                            color: barColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          dayLabel,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: isToday ? cs.primary : cs.outline,
                                    fontWeight: isToday
                                        ? FontWeight.w700
                                        : FontWeight.normal,
                                  ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendDot(color: cs.primary),
            const SizedBox(width: 4),
            Text(
              widget.isAR ? 'اليوم' : 'Today',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: cs.outline),
            ),
            const SizedBox(width: 16),
            _LegendDot(color: cs.primary.withValues(alpha: 0.45)),
            const SizedBox(width: 4),
            Text(
              widget.isAR ? 'أيام سابقة' : 'Previous days',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: cs.outline),
            ),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  const _LegendDot({required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

// ═══════════════════════════════════════════════════════════════════
//  STREAK ROW
// ═══════════════════════════════════════════════════════════════════

class _StreakRow extends StatelessWidget {
  final int current;
  final int longest;
  final bool isAR;

  const _StreakRow({
    required this.current,
    required this.longest,
    required this.isAR,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StreakCard(
            icon: '🔥',
            value: current,
            label: isAR ? 'التتالي الحالي' : 'Current Streak',
            unit: isAR ? 'يوم' : 'days',
            highlight: current > 0,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StreakCard(
            icon: '🏆',
            value: longest,
            label: isAR ? 'أطول تتالي' : 'Longest Streak',
            unit: isAR ? 'يوم' : 'days',
            highlight: false,
          ),
        ),
      ],
    );
  }
}

class _StreakCard extends StatelessWidget {
  final String icon;
  final int value;
  final String label;
  final String unit;
  final bool highlight;

  const _StreakCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.unit,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight
            ? Colors.orange.withValues(alpha: 0.08)
            : cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlight
              ? Colors.orange.withValues(alpha: 0.35)
              : cs.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$value',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: highlight ? Colors.orange.shade700 : cs.onSurface,
                      height: 1.0,
                    ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  unit,
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: cs.outline),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: cs.outline),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  ACTIVITY HEATMAP — 28-day grid (4 rows × 7 cols)
// ═══════════════════════════════════════════════════════════════════

class _ActivityHeatmap extends StatelessWidget {
  // ✅ FIX: List → List<int>
  final List<int> minutesPerDay; // 28 values, index 0 = oldest
  final bool isAR;

  const _ActivityHeatmap({
    required this.minutesPerDay,
    required this.isAR,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final locale = isAR ? 'ar' : 'en';
    final maxVal = minutesPerDay.fold(0, max).toDouble();

    // Day-of-week labels (Mon → Sun)
    final dowLabels = List.generate(7, (i) {
      final d = DateTime(2024, 1, 1 + i); // 2024-01-01 = Monday
      return DateFormat('E', locale).format(d);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // DOW header row
        Row(
          children: dowLabels
              .map((l) => Expanded(
                    child: Center(
                      child: Text(
                        l,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: cs.outline,
                              fontSize: 9,
                            ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 6),
        // 4 rows of 7 cells
        ...List.generate(4, (row) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              children: List.generate(7, (col) {
                final idx = row * 7 + col;
                final mins = minutesPerDay[idx];
                final frac = maxVal == 0 ? 0.0 : mins / maxVal;
                final date = now.subtract(Duration(days: 27 - idx));
                final isToday = idx == 27;
                final color = mins == 0
                    ? cs.surfaceContainerHighest
                    : Color.lerp(
                        cs.primary.withValues(alpha: 0.2),
                        cs.primary,
                        frac,
                      )!;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Tooltip(
                      message: '${DateFormat('d MMM', locale).format(date)}'
                          '${mins > 0 ? " · ${mins}m" : ""}',
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 400 + idx * 12),
                        height: 28,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(6),
                          border: isToday
                              ? Border.all(color: cs.primary, width: 1.5)
                              : null,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
        const SizedBox(height: 8),
        // Scale legend
        Row(
          children: [
            Text(
              isAR ? 'أقل' : 'Less',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: cs.outline, fontSize: 9),
            ),
            const SizedBox(width: 4),
            ...List.generate(5, (i) {
              final frac = i / 4.0;
              return Container(
                width: 14,
                height: 14,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: i == 0
                      ? cs.surfaceContainerHighest
                      : Color.lerp(
                          cs.primary.withValues(alpha: 0.2),
                          cs.primary,
                          frac,
                        ),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
            const SizedBox(width: 4),
            Text(
              isAR ? 'أكثر' : 'More',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: cs.outline, fontSize: 9),
            ),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  TIME-OF-DAY DISTRIBUTION CHART
// ═══════════════════════════════════════════════════════════════════

class _TimeOfDayChart extends StatefulWidget {
  // ✅ FIX: List → List<double>
  final List<double> fractions; // [morning, afternoon, evening, night]
  final bool isAR;

  const _TimeOfDayChart({
    required this.fractions,
    required this.isAR,
  });

  @override
  State<_TimeOfDayChart> createState() => _TimeOfDayChartState();
}

class _TimeOfDayChartState extends State<_TimeOfDayChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  // ✅ FIX: Animation → Animation<double>
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final segments = [
      _TODSegment(
        emoji: '🌅',
        label: widget.isAR ? 'صباح' : 'Morning',
        range: widget.isAR ? '5–12' : '5–12am',
        frac: widget.fractions[0],
        color: Colors.orange.shade300,
      ),
      _TODSegment(
        emoji: '☀️',
        label: widget.isAR ? 'ظهر' : 'Afternoon',
        range: widget.isAR ? '12–17' : '12–5pm',
        frac: widget.fractions[1],
        color: Colors.amber.shade500,
      ),
      _TODSegment(
        emoji: '🌇',
        label: widget.isAR ? 'مساء' : 'Evening',
        range: widget.isAR ? '17–21' : '5–9pm',
        frac: widget.fractions[2],
        color: cs.primary,
      ),
      _TODSegment(
        emoji: '🌙',
        label: widget.isAR ? 'ليل' : 'Night',
        range: widget.isAR ? '21–5' : '9pm–5am',
        frac: widget.fractions[3],
        color: Colors.deepPurple.shade300,
      ),
    ];

    return Row(
      children: [
        // Donut ring
        AnimatedBuilder(
          animation: _anim,
          builder: (_, __) => SizedBox(
            width: 110,
            height: 110,
            child: CustomPaint(
              painter: _DonutPainter(
                fractions: widget.fractions,
                colors: segments.map((s) => s.color).toList(),
                progress: _anim.value,
                trackColor: cs.surfaceContainerHighest,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      segments.reduce((a, b) => a.frac >= b.frac ? a : b).emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                    Text(
                      widget.isAR ? 'أكثر وقت' : 'Peak',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: cs.outline,
                            fontSize: 9,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        // Legend bars
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: segments.map((s) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Text(s.emoji, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                s.label,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: cs.onSurface,
                                    ),
                              ),
                              Text(
                                '${(s.frac * 100).round()}%',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: s.color,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          AnimatedBuilder(
                            animation: _anim,
                            builder: (_, __) => ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: s.frac * _anim.value,
                                minHeight: 6,
                                backgroundColor: cs.surfaceContainerHighest,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(s.color),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _TODSegment {
  final String emoji;
  final String label;
  final String range;
  final double frac;
  final Color color;

  const _TODSegment({
    required this.emoji,
    required this.label,
    required this.range,
    required this.frac,
    required this.color,
  });
}

// ── Donut painter ──────────────────────────────────────────────────

class _DonutPainter extends CustomPainter {
  // ✅ FIX: List → List<double>
  final List<double> fractions;
  // ✅ FIX: List → List<Color>
  final List<Color> colors;
  final double progress;
  final Color trackColor;

  const _DonutPainter({
    required this.fractions,
    required this.colors,
    required this.progress,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = size.width * 0.16;
    final radius = (size.width / 2) - strokeWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    double startAngle = -pi / 2;
    const gap = 0.04; // radians between segments

    for (int i = 0; i < fractions.length; i++) {
      if (fractions[i] <= 0) continue;
      final sweep = (2 * pi * fractions[i] * progress) - gap;
      if (sweep <= 0) continue;

      canvas.drawArc(
        rect,
        startAngle + gap / 2,
        sweep,
        false,
        Paint()
          ..color = colors[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
      startAngle += 2 * pi * fractions[i];
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.progress != progress || old.fractions != fractions;
}

// ═══════════════════════════════════════════════════════════════════
//  BEST SESSION CARD
// ═══════════════════════════════════════════════════════════════════

class _BestSessionCard extends StatelessWidget {
  final FocusLog log;
  final bool isAR;

  const _BestSessionCard({required this.log, required this.isAR});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final locale = isAR ? 'ar' : 'en';
    final local = log.timestamp.toLocal();
    final date = DateFormat('EEE, d MMM y', locale).format(local);
    final time = DateFormat('h:mm a', locale).format(local);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primaryContainer.withValues(alpha: 0.7),
            cs.secondaryContainer.withValues(alpha: 0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text('🏅', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                S.of(context, 'stats_best_session'),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${log.durationMinutes} min',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Task note
          Text(
            log.taskNote,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: isAR ? TextAlign.right : TextAlign.left,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 10),

          // Date + time row
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 12, color: cs.outline),
              const SizedBox(width: 4),
              Text(
                date,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: cs.outline),
              ),
              const SizedBox(width: 12),
              Icon(Icons.schedule_rounded, size: 12, color: cs.outline),
              const SizedBox(width: 4),
              Text(
                time,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: cs.outline),
              ),
              if (log.isStarred) ...[
                const SizedBox(width: 8),
                Icon(Icons.star_rounded,
                    size: 14, color: Colors.amber.shade600),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  EMPTY STATE
// ═══════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  final bool isAR;
  const _EmptyState({required this.isAR});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('📊', style: TextStyle(fontSize: 40)),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              isAR ? 'لا توجد إحصائيات بعد' : 'No stats yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              isAR
                  ? 'أكمل جلسة تركيز واحدة على الأقل لرؤية إحصائياتك هنا'
                  : 'Complete at least one focus session to see your stats here',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.outline,
                    height: 1.55,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
