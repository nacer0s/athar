// ═══════════════════════════════════════════════════════════════════
//  ATHAR (أثر) — lib/screens/log_screen.dart
// ═══════════════════════════════════════════════════════════════════

// ✅ dart:ui alias — avoids TextDirection getter crash caused by
//    Material widget shadowing the top-level identifier.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../l10n/strings.dart';
import '../models/focus_log.dart';
import '../widgets/adaptive_scaffold.dart';

// ───────────────────────────────────────────────────────────────────
//  FILTER ENUM
// ───────────────────────────────────────────────────────────────────

enum _LogFilter { all, starred, thisWeek }

// ───────────────────────────────────────────────────────────────────
//  LOG SCREEN
// ───────────────────────────────────────────────────────────────────

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  // ✅ FIX: State → State<LogScreen>
  State<LogScreen> createState() => _LogScreenState();
}

// ✅ FIX: State → State<LogScreen>
class _LogScreenState extends State<LogScreen>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  bool _searchOpen = false;
  _LogFilter _filter = _LogFilter.all;

  late final AnimationController _entryCtrl;
  // ✅ FIX: Animation → Animation<double>
  late final Animation<double> _entryFade;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    )..forward();
    _entryFade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  // ── Search toggle ──────────────────────────────────────────────
  void _toggleSearch() {
    HapticFeedback.lightImpact();
    setState(() {
      _searchOpen = !_searchOpen;
      if (!_searchOpen) {
        _searchCtrl.clear();
        _searchFocus.unfocus();
      } else {
        Future.delayed(
          const Duration(milliseconds: 200),
          () => _searchFocus.requestFocus(),
        );
      }
    });
  }

  // ── Filter ─────────────────────────────────────────────────────
  // ✅ FIX: List → List<FocusLog> (both param and return type)
  List<FocusLog> _applyFilter(List<FocusLog> all) {
    final query = _searchCtrl.text.trim().toLowerCase();
    final now = DateTime.now();

    return all.where((log) {
      if (query.isNotEmpty && !log.taskNote.toLowerCase().contains(query)) {
        return false;
      }
      switch (_filter) {
        case _LogFilter.starred:
          if (!log.isStarred) return false;
        case _LogFilter.thisWeek:
          final diff = now.difference(log.timestamp.toLocal()).inDays;
          if (diff > 6) return false;
        case _LogFilter.all:
          break;
      }
      return true;
    }).toList();
  }

  // ── Group by date ──────────────────────────────────────────────
  // ✅ FIX: all raw types restored — uses Dart 3 record (int, FocusLog)
  Map<String, List<(int, FocusLog)>> _group(
    List<FocusLog> source,
    List<FocusLog> allLogs,
    bool isAR,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final locale = isAR ? 'ar' : 'en';
    // ✅ FIX: raw Map literal → typed Map literal
    final result = <String, List<(int, FocusLog)>>{};

    for (final log in source) {
      final reversedIndex = allLogs.reversed.toList().indexOf(log);
      final local = log.timestamp.toLocal();
      final day = DateTime(local.year, local.month, local.day);

      final String key;
      if (day == today) {
        key = isAR ? 'اليوم' : 'Today';
      } else if (day == yesterday) {
        key = isAR ? 'أمس' : 'Yesterday';
      } else {
        key = DateFormat('EEEE, d MMM', locale).format(local);
      }

      result.putIfAbsent(key, () => []).add((reversedIndex, log));
    }

    return result;
  }

  // ── Delete with undo ───────────────────────────────────────────
  // All context-dependent values captured BEFORE the await gap —
  // no BuildContext is ever accessed after an async suspension.
  Future<void> _delete(int reversedIndex, BuildContext ctx) async {
    HapticFeedback.mediumImpact();

    final messenger = ScaffoldMessenger.of(ctx);
    final snackLabel = S.of(ctx, 'log_deleted_snack');
    final undoLabel = S.of(ctx, 'btn_undo');
    // ✅ FIX: ctx.read() → ctx.read<AppState>()
    final appState = ctx.read<AppState>();

    final deleted = await appState.deleteLog(reversedIndex);
    if (!mounted || deleted == null) return;

    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(snackLabel),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          action: SnackBarAction(
            label: undoLabel,
            onPressed: () => appState.restoreLog(deleted),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
  }

  // ════════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    // ✅ FIX: context.watch() → context.watch<AppState>()
    final state = context.watch<AppState>();
    final isAR = S.isRTL(context);
    final allLogs = state.logs;
    final filtered = _applyFilter(allLogs);
    final groups = _group(filtered, allLogs, isAR);

    return AdaptiveScaffold(
      title: S.of(context, 'logs_title'),
      actions: [
        AdaptiveScaffold.buildAction(
          context: context,
          icon: _searchOpen ? Icons.search_off_rounded : Icons.search_rounded,
          onPressed: _toggleSearch,
          tooltip: 'Search',
        ),
      ],
      body: FadeTransition(
        opacity: _entryFade,
        child: Column(
          children: [
            // ── Search bar ──────────────────────────────────────
            AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              child: _searchOpen
                  ? _SearchBar(
                      controller: _searchCtrl,
                      focusNode: _searchFocus,
                      isAR: isAR,
                    )
                  : const SizedBox.shrink(),
            ),

            // ── Filter chips ────────────────────────────────────
            _FilterChips(
              selected: _filter,
              onChanged: (f) {
                HapticFeedback.selectionClick();
                setState(() => _filter = f);
              },
              isAR: isAR,
            ),

            // ── Summary bar ─────────────────────────────────────
            if (allLogs.isNotEmpty) _SummaryBar(state: state, isAR: isAR),

            // ── List / empty state ───────────────────────────────
            Expanded(
              child: allLogs.isEmpty
                  ? _EmptyState(isFiltered: false, isAR: isAR)
                  : filtered.isEmpty
                      ? _EmptyState(isFiltered: true, isAR: isAR)
                      : _LogList(
                          groups: groups,
                          isAR: isAR,
                          onDelete: (idx) => _delete(idx, context),
                          onStar: (idx) {
                            HapticFeedback.selectionClick();
                            // ✅ FIX: context.read() → context.read<AppState>()
                            context.read<AppState>().toggleStar(idx);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────
//  SEARCH BAR
// ───────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isAR;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.isAR,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        // dart:ui alias prevents TextDirection getter-not-found crash
        textDirection: isAR ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        textAlign: isAR ? TextAlign.right : TextAlign.left,
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: S.of(context, 'log_search_hint'),
          hintStyle: TextStyle(color: cs.outline),
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: controller.clear,
                )
              : null,
          filled: true,
          fillColor: cs.surfaceContainerHigh,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: cs.primary.withValues(alpha: 0.5),
              width: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────
//  FILTER CHIPS
// ───────────────────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  final _LogFilter selected;
  final ValueChanged<_LogFilter> onChanged;
  final bool isAR;

  const _FilterChips({
    required this.selected,
    required this.onChanged,
    required this.isAR,
  });

  @override
  Widget build(BuildContext context) {
    final chips = [
      (_LogFilter.all, S.of(context, 'filter_all'), Icons.list_rounded),
      (_LogFilter.starred, S.of(context, 'filter_starred'), Icons.star_rounded),
      (
        _LogFilter.thisWeek,
        S.of(context, 'filter_this_week'),
        Icons.date_range_rounded
      ),
    ];

    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: chips.length,
        itemBuilder: (context, i) {
          final (filter, label, icon) = chips[i];
          final isSelected = selected == filter;
          final cs = Theme.of(context).colorScheme;

          return GestureDetector(
            onTap: () => onChanged(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color:
                    isSelected ? cs.primaryContainer : cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? cs.primary.withValues(alpha: 0.45)
                      : cs.outlineVariant.withValues(alpha: 0.4),
                  width: isSelected ? 1.4 : 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 14,
                    color: isSelected ? cs.primary : cs.outline,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: isSelected ? cs.primary : cs.outline,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────
//  SUMMARY BAR
// ───────────────────────────────────────────────────────────────────

class _SummaryBar extends StatelessWidget {
  final AppState state;
  final bool isAR;

  const _SummaryBar({required this.state, required this.isAR});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          _StatCell(
            icon: Icons.check_circle_outline_rounded,
            value: '${state.totalSessions}',
            label: isAR ? 'جلسة' : 'Sessions',
          ),
          _Divider(),
          _StatCell(
            icon: Icons.schedule_rounded,
            value: state.totalHours.toStringAsFixed(1),
            label: isAR ? 'ساعة' : 'Hours',
          ),
          _Divider(),
          _StatCell(
            icon: Icons.trending_up_rounded,
            value: '${state.avgSessionMinutes}',
            label: isAR ? 'د / جلسة' : 'min / avg',
          ),
          _Divider(),
          _StatCell(
            icon: Icons.star_rounded,
            value: '${state.logs.where((l) => l.isStarred).length}',
            label: isAR ? 'مميزة' : 'Starred',
            iconColor: Colors.amber.shade600,
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        height: 28,
        width: 1,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        color:
            Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
      );
}

class _StatCell extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? iconColor;

  const _StatCell({
    required this.icon,
    required this.value,
    required this.label,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: iconColor ?? cs.primary),
              const SizedBox(width: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 2),
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

// ───────────────────────────────────────────────────────────────────
//  LOG LIST — date-grouped
// ───────────────────────────────────────────────────────────────────

class _LogList extends StatelessWidget {
  // ✅ FIX: Map> → Map<String, List<(int, FocusLog)>>
  final Map<String, List<(int, FocusLog)>> groups;
  final bool isAR;
  // ✅ FIX: ValueChanged → ValueChanged<int>
  final ValueChanged<int> onDelete;
  // ✅ FIX: ValueChanged → ValueChanged<int>
  final ValueChanged<int> onStar;

  const _LogList({
    required this.groups,
    required this.isAR,
    required this.onDelete,
    required this.onStar,
  });

  @override
  Widget build(BuildContext context) {
    final keys = groups.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      itemCount: keys.length,
      itemBuilder: (context, sectionIndex) {
        final key = keys[sectionIndex];
        final items = groups[key]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
              child: Text(
                key,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
              ),
            ),
            ...items.asMap().entries.map((entry) {
              final itemIndex = entry.key;
              final (reversedIdx, log) = entry.value;

              return _AnimatedLogTile(
                log: log,
                reversedIndex: reversedIdx,
                staggerIndex: sectionIndex * 10 + itemIndex,
                isAR: isAR,
                onDelete: () => onDelete(reversedIdx),
                onStar: () => onStar(reversedIdx),
              );
            }),
          ],
        );
      },
    );
  }
}

// ───────────────────────────────────────────────────────────────────
//  ANIMATED LOG TILE
// ───────────────────────────────────────────────────────────────────

class _AnimatedLogTile extends StatefulWidget {
  final FocusLog log;
  final int reversedIndex;
  final int staggerIndex;
  final bool isAR;
  final VoidCallback onDelete;
  final VoidCallback onStar;

  const _AnimatedLogTile({
    required this.log,
    required this.reversedIndex,
    required this.staggerIndex,
    required this.isAR,
    required this.onDelete,
    required this.onStar,
  });

  @override
  State<_AnimatedLogTile> createState() => _AnimatedLogTileState();
}

class _AnimatedLogTileState extends State<_AnimatedLogTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  // ✅ FIX: Animation → Animation<double>
  late final Animation<double> _fade;
  // ✅ FIX: Animation → Animation<Offset>
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    // ✅ FIX: Tween → Tween<Offset>
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    final delay = Duration(
      milliseconds: (widget.staggerIndex * 40).clamp(0, 300),
    );
    Future.delayed(delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: _LogTile(
          log: widget.log,
          reversedIndex: widget.reversedIndex,
          isAR: widget.isAR,
          onDelete: widget.onDelete,
          onStar: widget.onStar,
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────
//  LOG TILE
// ───────────────────────────────────────────────────────────────────

class _LogTile extends StatelessWidget {
  final FocusLog log;
  final int reversedIndex;
  final bool isAR;
  final VoidCallback onDelete;
  final VoidCallback onStar;

  const _LogTile({
    required this.log,
    required this.reversedIndex,
    required this.isAR,
    required this.onDelete,
    required this.onStar,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final locale = isAR ? 'ar' : 'en';
    final local = log.timestamp.toLocal();
    final time = DateFormat('h:mm a', locale).format(local);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey(log.key),
        direction: DismissDirection.endToStart,
        background: _SwipeBackground(),
        confirmDismiss: (_) async {
          onDelete();
          return false;
        },
        child: Container(
          decoration: BoxDecoration(
            color: log.isStarred
                ? Colors.amber.withValues(alpha: 0.05)
                : cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: log.isStarred
                  ? Colors.amber.withValues(alpha: 0.35)
                  : cs.outlineVariant.withValues(alpha: 0.35),
              width: log.isStarred ? 1.3 : 1.0,
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 4,
                  decoration: BoxDecoration(
                    color: log.isStarred
                        ? Colors.amber.shade500
                        : cs.primary.withValues(alpha: 0.6),
                    borderRadius: isAR
                        ? const BorderRadius.only(
                            topRight: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          )
                        : const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                          ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                    child: Column(
                      crossAxisAlignment: isAR
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.taskNote,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          textAlign: isAR ? TextAlign.right : TextAlign.left,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    height: 1.45,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: isAR
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          children: [
                            _MetaChip(
                              icon: Icons.timer_outlined,
                              label: S.fmt(context, 'log_duration_label',
                                  {'n': '${log.durationMinutes}'}),
                            ),
                            const SizedBox(width: 8),
                            _MetaChip(
                              icon: Icons.schedule_rounded,
                              label: time,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                _StarButton(isStarred: log.isStarred, onTap: onStar),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Swipe background ───────────────────────────────────────────────

class _SwipeBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.centerRight,
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(Icons.delete_outline_rounded,
              color: cs.onErrorContainer, size: 22),
          const SizedBox(width: 6),
          Text(
            S.of(context, 'btn_delete'),
            style: TextStyle(
              color: cs.onErrorContainer,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Meta chip ──────────────────────────────────────────────────────

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: cs.outline),
        const SizedBox(width: 3),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: cs.outline),
        ),
      ],
    );
  }
}

// ── Star button ────────────────────────────────────────────────────

class _StarButton extends StatelessWidget {
  final bool isStarred;
  final VoidCallback onTap;

  const _StarButton({required this.isStarred, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.elasticOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: Icon(
            isStarred ? Icons.star_rounded : Icons.star_outline_rounded,
            key: ValueKey(isStarred),
            color: isStarred
                ? Colors.amber.shade600
                : Theme.of(context).colorScheme.outline,
            size: 22,
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────
//  EMPTY STATE
// ───────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isFiltered;
  final bool isAR;

  const _EmptyState({required this.isFiltered, required this.isAR});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final emoji = isFiltered ? '🔍' : '🌱';
    final title = isFiltered
        ? (isAR ? 'لا توجد نتائج' : 'No results found')
        : (isAR ? 'لا توجد جلسات بعد' : 'No sessions yet');
    final body = isFiltered
        ? (isAR
            ? 'جرّب تغيير الفلتر أو مصطلح البحث'
            : 'Try adjusting your filter or search term')
        : (isAR
            ? 'أكمل جلسة تركيز لتراها هنا'
            : 'Complete a focus session to see it here');

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.outline,
                    height: 1.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
