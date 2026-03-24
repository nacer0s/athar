// ═══════════════════════════════════════════════════════════════════
//  ATHAR (أثر) — lib/screens/settings_screen.dart
//
//  UX highlights:
//  • Grouped card sections (Focus / Appearance / Notifications / Data)
//  • Animated duration wheel picker (iOS) / slider+chip grid (Android)
//  • Theme picker with live preview swatches
//  • Language toggle with flag + animated indicator
//  • Notification toggles with permission-aware guards
//  • Clear all data with double-confirmation sheet
//  • App version + about section
//  • Full RTL / LTR support
// ═══════════════════════════════════════════════════════════════════

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../l10n/strings.dart';
import '../widgets/adaptive_button.dart';
import '../widgets/adaptive_scaffold.dart';

// ───────────────────────────────────────────────────────────────────
//  CONSTANTS
// ───────────────────────────────────────────────────────────────────

const String _kAppVersion = '1.0.0';
const String _kBuildNum = '1';

// ✅ FIX: List → List<int>
const List<int> _kDurationPresets = [5, 10, 15, 20, 25, 30, 45, 60, 90];

// ═══════════════════════════════════════════════════════════════════
//  SETTINGS SCREEN
// ═══════════════════════════════════════════════════════════════════

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  // ✅ FIX: State → State<SettingsScreen>
  State<SettingsScreen> createState() => _SettingsScreenState();
}

// ✅ FIX: State → State<SettingsScreen>
class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
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
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  // ── Clear all data ─────────────────────────────────────────────
  // ✅ FIX: Future → Future<void>
  Future<void> _confirmClearAll(BuildContext ctx) async {
    HapticFeedback.mediumImpact();
    final confirmed = await _showClearSheet(ctx);
    if (confirmed == true && ctx.mounted) {
      // ✅ FIX: ctx.read() → ctx.read<AppState>()
      await ctx.read<AppState>().clearAllLogs();
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text(S.of(ctx, 'settings_cleared_snack')),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  // ✅ FIX: Future → Future<bool?>
  Future<bool?> _showClearSheet(BuildContext ctx) {
    if (Platform.isIOS) {
      // ✅ FIX: showCupertinoModalPopup → showCupertinoModalPopup<bool?>
      return showCupertinoModalPopup<bool?>(
        context: ctx,
        builder: (_) => CupertinoActionSheet(
          title: Text(S.of(ctx, 'settings_clear_title')),
          message: Text(S.of(ctx, 'settings_clear_body')),
          actions: [
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(S.of(ctx, 'settings_clear_confirm')),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(S.of(ctx, 'btn_cancel')),
          ),
        ),
      );
    }

    // ✅ FIX: showModalBottomSheet → showModalBottomSheet<bool?>
    return showModalBottomSheet<bool?>(
      context: ctx,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ClearDataSheet(
        onConfirm: () => Navigator.pop(ctx, true),
        onCancel: () => Navigator.pop(ctx, false),
      ),
    );
  }

  // ── Duration picker ────────────────────────────────────────────
  void _showDurationPicker(BuildContext ctx, AppState state) {
    HapticFeedback.lightImpact();
    if (Platform.isIOS) {
      _showIOSDurationPicker(ctx, state);
    } else {
      _showAndroidDurationSheet(ctx, state);
    }
  }

  void _showIOSDurationPicker(BuildContext ctx, AppState state) {
    int tempDuration = state.focusDurationMinutes;

    // ✅ FIX: showCupertinoModalPopup → showCupertinoModalPopup<void>
    showCupertinoModalPopup<void>(
      context: ctx,
      builder: (_) => Container(
        height: 300,
        color: CupertinoColors.systemBackground.resolveFrom(ctx),
        child: Column(
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: Text(S.of(ctx, 'btn_cancel')),
                  onPressed: () => Navigator.pop(ctx),
                ),
                Text(
                  S.of(ctx, 'settings_duration_picker_title'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                CupertinoButton(
                  child: Text(
                    S.of(ctx, 'btn_done'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  onPressed: () {
                    // ✅ FIX: ctx.read() → ctx.read<AppState>()
                    ctx.read<AppState>().setFocusDuration(tempDuration);
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
            // Wheel
            Expanded(
              child: CupertinoPicker(
                itemExtent: 44,
                scrollController: FixedExtentScrollController(
                  initialItem: tempDuration - 1,
                ),
                onSelectedItemChanged: (i) {
                  HapticFeedback.selectionClick();
                  tempDuration = i + 1;
                },
                children: List.generate(
                  120,
                  (i) => Center(
                    child: Text(
                      '${i + 1} min',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAndroidDurationSheet(BuildContext ctx, AppState state) {
    // ✅ FIX: showModalBottomSheet → showModalBottomSheet<void>
    showModalBottomSheet<void>(
      context: ctx,
      useRootNavigator: false,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DurationSheet(
        current: state.focusDurationMinutes,
        // ✅ FIX: ctx.read() → ctx.read<AppState>()
        onChanged: (v) => ctx.read<AppState>().setFocusDuration(v),
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

    return AdaptiveScaffold(
      title: S.of(context, 'settings_title'),
      body: FadeTransition(
        opacity: _entryFade,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          children: [
            // ── 1. Focus ───────────────────────────────────────
            _SectionHeader(label: S.of(context, 'settings_section_focus')),
            _SettingsCard(
              children: [
                _TileDuration(
                  minutes: state.focusDurationMinutes,
                  isAR: isAR,
                  onTap: state.status == TimerStatus.idle
                      ? () => _showDurationPicker(context, state)
                      : null,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── 2. Appearance ──────────────────────────────────
            _SectionHeader(label: S.of(context, 'settings_section_appearance')),
            _SettingsCard(
              children: [
                _TileLanguage(
                  isAR: isAR,
                  onToggle: () {
                    HapticFeedback.selectionClick();
                    // ✅ FIX: context.read() → context.read<AppState>()
                    context.read<AppState>().toggleLocale();
                  },
                ),
                _Separator(),
                _TileTheme(
                  current: state.themeMode,
                  isAR: isAR,
                  onChanged: (m) {
                    HapticFeedback.selectionClick();
                    // ✅ FIX: context.read() → context.read<AppState>()
                    context.read<AppState>().setThemeMode(m);
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── 3. Notifications ───────────────────────────────
            _SectionHeader(
                label: S.of(context, 'settings_section_notifications')),
            _SettingsCard(
              children: [
                _TileSwitch(
                  icon: Icons.notifications_outlined,
                  iconColor: Theme.of(context).colorScheme.primary,
                  title: S.of(context, 'settings_notify_complete'),
                  subtitle: S.of(context, 'settings_notify_complete_sub'),
                  value: state.notifyOnComplete,
                  onChanged: (v) {
                    HapticFeedback.selectionClick();
                    // ✅ FIX: context.read() → context.read<AppState>()
                    context.read<AppState>().setNotifyOnComplete(v);
                  },
                ),
                _Separator(),
                _TileSwitch(
                  icon: Icons.alarm_outlined,
                  iconColor: Colors.orange.shade600,
                  title: S.of(context, 'settings_daily_reminder'),
                  subtitle: S.of(context, 'settings_daily_reminder_sub'),
                  value: state.dailyReminder,
                  onChanged: (v) {
                    HapticFeedback.selectionClick();
                    // ✅ FIX: context.read() → context.read<AppState>()
                    context.read<AppState>().setDailyReminder(v);
                  },
                ),
                _Separator(),
                _TileSwitch(
                  icon: Icons.vibration_rounded,
                  iconColor: Colors.purple.shade400,
                  title: S.of(context, 'settings_vibrate'),
                  subtitle: S.of(context, 'settings_vibrate_sub'),
                  value: state.vibrateOnComplete,
                  onChanged: (v) {
                    HapticFeedback.selectionClick();
                    // ✅ FIX: context.read() → context.read<AppState>()
                    context.read<AppState>().setVibrateOnComplete(v);
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── 4. Data ────────────────────────────────────────
            _SectionHeader(label: S.of(context, 'settings_section_data')),
            _SettingsCard(
              children: [
                _TileStats(state: state, isAR: isAR),
                _Separator(),
                _TileAction(
                  icon: Icons.delete_sweep_outlined,
                  iconColor: Theme.of(context).colorScheme.error,
                  title: S.of(context, 'settings_clear_data'),
                  subtitle: S.of(context, 'settings_clear_data_sub'),
                  trailing: Text(
                    S.of(context, 'settings_clear_data_btn'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  enabled: state.totalSessions > 0,
                  onTap: state.totalSessions > 0
                      ? () => _confirmClearAll(context)
                      : null,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── 5. About ───────────────────────────────────────
            _SectionHeader(label: S.of(context, 'settings_section_about')),
            _SettingsCard(
              children: [
                _TileAbout(isAR: isAR),
                _Separator(),
                _TileAction(
                  icon: Icons.info_outline_rounded,
                  iconColor: Theme.of(context).colorScheme.secondary,
                  title: S.of(context, 'settings_version'),
                  subtitle: 'v$_kAppVersion ($_kBuildNum)',
                  trailing: const SizedBox.shrink(),
                  onTap: null,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // ── Footer ─────────────────────────────────────────
            Center(
              child: Text(
                isAR
                    ? 'صُنع بـ ♥ لمساعدتك على التركيز'
                    : 'Made with ♥ to help you focus',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.6),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────
//  SECTION HEADER
// ───────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────
//  SETTINGS CARD — rounded container for grouped tiles
// ───────────────────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────
//  SEPARATOR
// ───────────────────────────────────────────────────────────────────

class _Separator extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Divider(
        height: 1,
        indent: 54,
        endIndent: 0,
        color: Theme.of(context)
            .colorScheme
            .outlineVariant
            .withValues(alpha: 0.35),
      );
}

// ───────────────────────────────────────────────────────────────────
//  ICON BOX — coloured rounded square
// ───────────────────────────────────────────────────────────────────

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconBox({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}

// ───────────────────────────────────────────────────────────────────
//  TILE — DURATION
// ───────────────────────────────────────────────────────────────────

class _TileDuration extends StatelessWidget {
  final int minutes;
  final bool isAR;
  final VoidCallback? onTap;

  const _TileDuration({
    required this.minutes,
    required this.isAR,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final enabled = onTap != null;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      leading: _IconBox(icon: Icons.timer_outlined, color: cs.primary),
      title: Text(
        S.of(context, 'settings_focus_duration'),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: enabled ? cs.onSurface : cs.outline,
            ),
      ),
      subtitle: enabled
          ? null
          : Text(
              S.of(context, 'settings_duration_locked'),
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: cs.outline),
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$minutes min',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          if (enabled) ...[
            const SizedBox(width: 6),
            Icon(
              isAR ? CupertinoIcons.chevron_left : CupertinoIcons.chevron_right,
              size: 15,
              color: cs.outline,
            ),
          ],
        ],
      ),
      onTap: onTap,
    );
  }
}

// ───────────────────────────────────────────────────────────────────
//  TILE — LANGUAGE
// ───────────────────────────────────────────────────────────────────

class _TileLanguage extends StatelessWidget {
  final bool isAR;
  final VoidCallback onToggle;

  const _TileLanguage({required this.isAR, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      leading:
          _IconBox(icon: Icons.language_rounded, color: Colors.teal.shade600),
      title: Text(
        S.of(context, 'settings_language'),
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(fontWeight: FontWeight.w500),
      ),
      trailing: GestureDetector(
        onTap: onToggle,
        child: Container(
          height: 34,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LangTab(label: 'EN', flag: '🇬🇧', selected: !isAR),
              _LangTab(label: 'ع', flag: '🇸🇦', selected: isAR),
            ],
          ),
        ),
      ),
      onTap: onToggle,
    );
  }
}

class _LangTab extends StatelessWidget {
  final String label;
  final String flag;
  final bool selected;

  const _LangTab({
    required this.label,
    required this.flag,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      height: 34,
      decoration: BoxDecoration(
        color: selected ? cs.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(flag, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selected ? cs.primary : cs.outline,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────
//  TILE — THEME
// ───────────────────────────────────────────────────────────────────

class _TileTheme extends StatelessWidget {
  final ThemeMode current;
  final bool isAR;
  // ✅ FIX: ValueChanged → ValueChanged<ThemeMode>
  final ValueChanged<ThemeMode> onChanged;

  const _TileTheme({
    required this.current,
    required this.isAR,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final options = [
      (
        ThemeMode.system,
        Icons.brightness_auto_rounded,
        S.of(context, 'theme_system')
      ),
      (ThemeMode.light, Icons.wb_sunny_rounded, S.of(context, 'theme_light')),
      (ThemeMode.dark, Icons.nightlight_rounded, S.of(context, 'theme_dark')),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          _IconBox(
              icon: Icons.palette_outlined, color: Colors.deepPurple.shade400),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  isAR ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  S.of(context, 'settings_theme'),
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 10),
                Row(
                  children: options.map((opt) {
                    final (mode, icon, label) = opt;
                    final sel = current == mode;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => onChanged(mode),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: sel
                                ? cs.primaryContainer
                                : cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: sel
                                  ? cs.primary.withValues(alpha: 0.4)
                                  : Colors.transparent,
                              width: 1.3,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(icon,
                                  size: 18,
                                  color: sel ? cs.primary : cs.outline),
                              const SizedBox(height: 4),
                              Text(
                                label,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: sel ? cs.primary : cs.outline,
                                      fontWeight: sel
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────
//  TILE — SWITCH
// ───────────────────────────────────────────────────────────────────

class _TileSwitch extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  // ✅ FIX: ValueChanged → ValueChanged<bool>
  final ValueChanged<bool> onChanged;

  const _TileSwitch({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: _IconBox(icon: icon, color: iconColor),
      title: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
      ),
      trailing: Switch.adaptive(value: value, onChanged: onChanged),
      onTap: () => onChanged(!value),
    );
  }
}

// ───────────────────────────────────────────────────────────────────
//  TILE — ACTION (chevron / custom trailing)
// ───────────────────────────────────────────────────────────────────

class _TileAction extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget trailing;
  final bool enabled;
  final VoidCallback? onTap;

  const _TileAction({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.enabled = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      enabled: enabled,
      leading: _IconBox(icon: icon, color: iconColor),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: enabled ? cs.onSurface : cs.outline,
            ),
      ),
      subtitle: Text(
        subtitle,
        style:
            Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.outline),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

// ───────────────────────────────────────────────────────────────────
//  TILE — STATS SUMMARY (read-only)
// ───────────────────────────────────────────────────────────────────

class _TileStats extends StatelessWidget {
  final AppState state;
  final bool isAR;

  const _TileStats({required this.state, required this.isAR});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final stats = [
      (
        Icons.check_circle_outline_rounded,
        cs.primary,
        '${state.totalSessions}',
        S.of(context, 'stat_sessions')
      ),
      (
        Icons.schedule_rounded,
        Colors.teal.shade600,
        state.totalHours.toStringAsFixed(1),
        S.of(context, 'stat_hours')
      ),
      (
        Icons.star_rounded,
        Colors.amber.shade600,
        '${state.logs.where((l) => l.isStarred).length}',
        S.of(context, 'stat_starred')
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          _IconBox(icon: Icons.bar_chart_rounded, color: cs.secondary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  isAR ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  S.of(context, 'settings_your_data'),
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 10),
                Row(
                  children: stats.map((s) {
                    final (icon, color, value, label) = s;
                    return Expanded(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(icon, size: 13, color: color),
                              const SizedBox(width: 3),
                              Text(
                                value,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
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
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────
//  TILE — ABOUT
// ───────────────────────────────────────────────────────────────────

class _TileAbout extends StatelessWidget {
  final bool isAR;
  const _TileAbout({required this.isAR});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primary, cs.tertiary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text(
                'أ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  isAR ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  'Athar أثر',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  isAR
                      ? 'تطبيق التركيز والإنتاجية'
                      : 'Focus & productivity tracker',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: cs.outline),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  DURATION SHEET — Android bottom sheet with chip grid + slider
// ═══════════════════════════════════════════════════════════════════

class _DurationSheet extends StatefulWidget {
  final int current;
  // ✅ FIX: ValueChanged → ValueChanged<int>
  final ValueChanged<int> onChanged;

  const _DurationSheet({
    required this.current,
    required this.onChanged,
  });

  @override
  State<_DurationSheet> createState() => _DurationSheetState();
}

class _DurationSheetState extends State<_DurationSheet> {
  late int _value;

  @override
  void initState() {
    super.initState();
    _value = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isAR = S.isRTL(context);

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title + value badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    S.of(context, 'settings_duration_picker_title'),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$_value min',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Preset chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _kDurationPresets.map((p) {
                  final sel = _value == p;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _value = p);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color:
                            sel ? cs.primaryContainer : cs.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel
                              ? cs.primary.withValues(alpha: 0.5)
                              : cs.outlineVariant.withValues(alpha: 0.4),
                          width: sel ? 1.4 : 1.0,
                        ),
                      ),
                      child: Text(
                        '$p min',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: sel ? cs.primary : cs.outline,
                              fontWeight:
                                  sel ? FontWeight.w700 : FontWeight.normal,
                            ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // Fine-tune slider (1–120 min)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAR ? 'ضبط دقيق' : 'Fine-tune',
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: cs.outline),
                  ),
                  Slider.adaptive(
                    value: _value.toDouble(),
                    min: 1,
                    max: 120,
                    divisions: 119,
                    label: '$_value',
                    onChanged: (v) => setState(() => _value = v.round()),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('1 min',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: cs.outline)),
                      Text('120 min',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: cs.outline)),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Confirm button
              SizedBox(
                width: double.infinity,
                child: AdaptiveButton(
                  label: S.of(context, 'btn_done'),
                  onPressed: () {
                    widget.onChanged(_value);
                    Navigator.pop(context);
                  },
                  size: AdaptiveButtonSize.large,
                  fullWidth: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  CLEAR DATA SHEET — Android bottom sheet
// ═══════════════════════════════════════════════════════════════════

class _ClearDataSheet extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _ClearDataSheet({
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Warning icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: cs.errorContainer.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_forever_rounded,
                color: cs.error,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              S.of(context, 'settings_clear_title'),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              S.of(context, 'settings_clear_body'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.outline,
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: AdaptiveButton(
                    label: S.of(context, 'btn_cancel'),
                    onPressed: onCancel,
                    variant: AdaptiveButtonVariant.secondary,
                    fullWidth: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AdaptiveButton(
                    label: S.of(context, 'settings_clear_confirm'),
                    onPressed: onConfirm,
                    variant: AdaptiveButtonVariant.destructive,
                    fullWidth: true,
                    icon: Icons.delete_forever_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
