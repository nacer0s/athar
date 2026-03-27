// ═══════════════════════════════════════════════════════════════════
//  Athar (أثر) — lib/screens/input_screen.dart
// ═══════════════════════════════════════════════════════════════════

import 'dart:io';
import 'dart:ui' as ui; // explicit alias — avoids TextDirection shadowing

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../l10n/strings.dart';
import '../widgets/adaptive_button.dart';

// ───────────────────────────────────────────────────────────────────
//  CONSTANTS
// ───────────────────────────────────────────────────────────────────

const int _kMaxChars = 200;
const int _kWarnChars = 160;

// ───────────────────────────────────────────────────────────────────
//  QUICK TAGS
// ───────────────────────────────────────────────────────────────────

class _Tag {
  final String emoji;
  final String labelEn;
  final String labelAr;
  const _Tag(this.emoji, this.labelEn, this.labelAr);
}

const List<_Tag> _kTags = [
  _Tag('🧠', 'Deep Work', 'عمل عميق'),
  _Tag('📖', 'Reading', 'قراءة'),
  _Tag('💻', 'Coding', 'برمجة'),
  _Tag('✍️', 'Writing', 'كتابة'),
  _Tag('🎨', 'Design', 'تصميم'),
  _Tag('📋', 'Planning', 'تخطيط'),
  _Tag('🎵', 'Music', 'موسيقى'),
  _Tag('📚', 'Study', 'دراسة'),
];

// ═══════════════════════════════════════════════════════════════════
//  INPUT SCREEN
// ═══════════════════════════════════════════════════════════════════

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  // ✅ FIX: State → State<InputScreen>
  State<InputScreen> createState() => _InputScreenState();
}

// ✅ FIX: State → State<InputScreen>
class _InputScreenState extends State<InputScreen>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isStarred = false;
  bool _isSaving = false;
  int? _selectedTag;
  bool get _isDirty => _controller.text.trim().isNotEmpty;

  late final AnimationController _entryCtrl;
  // ✅ FIX: Animation → Animation<double>
  late final Animation<double> _entryFade;
  // ✅ FIX: Animation → Animation<Offset>
  late final Animation<Offset> _entrySlide;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _entryFade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    // ✅ FIX: Tween → Tween<Offset>
    _entrySlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));

    _entryCtrl.forward();

    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  // ── Save ───────────────────────────────────────────────────────
  // ✅ FIX: Future → Future<void>
  Future<void> _save() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      _focusNode.requestFocus();
      _shakeField();
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final tagSuffix =
        _selectedTag != null ? ' ${_kTags[_selectedTag!].emoji}' : '';

    // ✅ FIX: context.read() → context.read<AppState>()
    await context
        .read<AppState>()
        .saveLog('$text$tagSuffix', isStarred: _isStarred);

    if (mounted) Navigator.of(context, rootNavigator: true).pop();
  }

  // ── Discard ────────────────────────────────────────────────────
  // ✅ FIX: Future → Future<void>
  Future<void> _confirmDiscard() async {
    if (!_isDirty) {
      Navigator.of(context, rootNavigator: true).pop();
      return;
    }
    HapticFeedback.lightImpact();
    final confirmed = await _showDiscardSheet();
    if (confirmed == true && mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  // ✅ FIX: Future → Future<bool?>
  Future<bool?> _showDiscardSheet() {
    if (Platform.isIOS) {
      return showCupertinoModalPopup<bool?>(
        context: context,
        builder: (_) => CupertinoActionSheet(
          title: Text(S.of(context, 'discard_title')),
          message: Text(S.of(context, 'discard_body')),
          actions: [
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(context, true),
              child: Text(S.of(context, 'discard_confirm')),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, false),
            child: Text(S.of(context, 'btn_cancel')),
          ),
        ),
      );
    }

    return showModalBottomSheet<bool?>(
      context: context,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DiscardSheet(
        onConfirm: () => Navigator.pop(context, true),
        onCancel: () => Navigator.pop(context, false),
      ),
    );
  }

  void _shakeField() {
    HapticFeedback.heavyImpact();
    setState(() {});
  }

  void _onTagTap(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedTag = _selectedTag == index ? null : index;
      if (_selectedTag != null && _controller.text.trim().isEmpty) {
        final isAR = S.isRTL(context);
        final label = isAR
            ? _kTags[_selectedTag!].labelAr
            : _kTags[_selectedTag!].labelEn;
        _controller.text = label;
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
      }
    });
  }

  // ════════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    // ✅ FIX: context.watch() → context.watch<AppState>()
    final state = context.watch<AppState>();
    final isAR = S.isRTL(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await _confirmDiscard();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: _buildAppBar(context, isAR),
        body: FadeTransition(
          opacity: _entryFade,
          child: SlideTransition(
            position: _entrySlide,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SessionSummaryCard(state: state),
                    const SizedBox(height: 28),
                    _SectionLabel(label: S.of(context, 'input_task_label')),
                    const SizedBox(height: 10),
                    _NoteField(
                      controller: _controller,
                      focusNode: _focusNode,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 6),
                    _CharCounter(length: _controller.text.length),
                    const SizedBox(height: 24),
                    _SectionLabel(label: S.of(context, 'input_tags_label')),
                    const SizedBox(height: 10),
                    _TagChips(
                      selectedIndex: _selectedTag,
                      isAR: isAR,
                      onTap: _onTagTap,
                    ),
                    const SizedBox(height: 28),
                    _StarRow(
                      isStarred: _isStarred,
                      onToggle: (v) {
                        HapticFeedback.selectionClick();
                        setState(() => _isStarred = v);
                      },
                    ),
                    const SizedBox(height: 32),
                    AdaptiveLoadingButton(
                      label: S.of(context, 'btn_save'),
                      onPressed: _isDirty ? _save : null,
                      isLoading: _isSaving,
                      size: AdaptiveButtonSize.large,
                      fullWidth: true,
                      icon: Icons.check_rounded,
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: AdaptiveTextButton(
                        label: S.of(context, 'btn_discard'),
                        onPressed: _confirmDiscard,
                        isDestructive: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isAR) {
    final cs = Theme.of(context).colorScheme;

    return AppBar(
      backgroundColor: cs.surface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      centerTitle: true,
      leading: AdaptiveIconButton(
        icon: Platform.isIOS ? CupertinoIcons.xmark : Icons.close_rounded,
        onPressed: _confirmDiscard,
        tooltip: S.of(context, 'btn_discard'),
      ),
      title: Text(
        S.of(context, 'input_title'),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
      actions: [
        _StarIconButton(
          isStarred: _isStarred,
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _isStarred = !_isStarred);
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

// ───────────────────────────────────────────────────────────────────
//  SESSION SUMMARY CARD
// ───────────────────────────────────────────────────────────────────

class _SessionSummaryCard extends StatelessWidget {
  final AppState state;
  const _SessionSummaryCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final isAR = S.isRTL(context);
    final locale = isAR ? 'ar' : 'en';
    final timeStr = DateFormat('h:mm a', locale).format(now);
    final dateStr = DateFormat('EEE, d MMM', locale).format(now);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primaryContainer.withValues(alpha: 0.55),
            cs.secondaryContainer.withValues(alpha: 0.30),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_rounded, color: cs.primary, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.fmt(context, 'log_duration_label',
                      {'n': '${state.focusDurationMinutes}'}),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$timeStr · $dateStr',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.outline,
                      ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${state.totalSessions + 1}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
              ),
              Text(
                isAR ? 'جلسة' : 'sessions',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.outline,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────
//  SECTION LABEL
// ───────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────
//  NOTE TEXT FIELD
// ───────────────────────────────────────────────────────────────────

class _NoteField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  // ✅ FIX: ValueChanged → ValueChanged<String>
  final ValueChanged<String> onChanged;

  const _NoteField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isAR = S.isRTL(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: focusNode.hasFocus
              ? cs.primary.withValues(alpha: 0.6)
              : cs.outlineVariant.withValues(alpha: 0.5),
          width: focusNode.hasFocus ? 1.5 : 1.0,
        ),
        boxShadow: focusNode.hasFocus
            ? [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.07),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        maxLines: 5,
        minLines: 4,
        maxLength: _kMaxChars,
        buildCounter: (_,
                {required currentLength, required isFocused, maxLength}) =>
            null,
        // dart:ui alias prevents TextDirection getter-not-found crash
        // caused by Material widget shadowing the top-level identifier.
        textDirection: isAR ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        textAlign: isAR ? TextAlign.right : TextAlign.left,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.55),
        decoration: InputDecoration(
          hintText: S.of(context, 'input_hint'),
          hintStyle: TextStyle(color: cs.outline),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────
//  CHARACTER COUNTER
// ───────────────────────────────────────────────────────────────────

class _CharCounter extends StatelessWidget {
  final int length;
  const _CharCounter({required this.length});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final remaining = _kMaxChars - length;
    final color = remaining < (_kMaxChars - _kWarnChars)
        ? cs.error
        : remaining < 50
            ? Colors.amber.shade700
            : cs.outline;

    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 200),
        style: Theme.of(context).textTheme.labelSmall!.copyWith(color: color),
        child: Text('$length / $_kMaxChars'),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────
//  TAG CHIPS
// ───────────────────────────────────────────────────────────────────

class _TagChips extends StatelessWidget {
  final int? selectedIndex;
  final bool isAR;
  // ✅ FIX: ValueChanged → ValueChanged<int>
  final ValueChanged<int> onTap;

  const _TagChips({
    required this.selectedIndex,
    required this.isAR,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(_kTags.length, (i) {
        final tag = _kTags[i];
        final selected = selectedIndex == i;
        final cs = Theme.of(context).colorScheme;
        final label = isAR ? tag.labelAr : tag.labelEn;

        return GestureDetector(
          onTap: () => onTap(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: selected ? cs.primaryContainer : cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? cs.primary.withValues(alpha: 0.55)
                    : cs.outlineVariant.withValues(alpha: 0.4),
                width: selected ? 1.4 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(tag.emoji, style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: selected ? cs.primary : cs.onSurface,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.normal,
                      ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ───────────────────────────────────────────────────────────────────
//  STAR ROW
// ───────────────────────────────────────────────────────────────────

class _StarRow extends StatelessWidget {
  final bool isStarred;
  // ✅ FIX: ValueChanged → ValueChanged<bool>
  final ValueChanged<bool> onToggle;

  const _StarRow({required this.isStarred, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isAR = S.isRTL(context);

    return GestureDetector(
      onTap: () => onToggle(!isStarred),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isStarred
              ? Colors.amber.withValues(alpha: 0.08)
              : cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isStarred
                ? Colors.amber.withValues(alpha: 0.45)
                : cs.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.elasticOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(
                isStarred ? Icons.star_rounded : Icons.star_outline_rounded,
                key: ValueKey(isStarred),
                color: isStarred ? Colors.amber.shade600 : cs.outline,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    isAR ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    S.of(context, 'input_star_label'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color:
                              isStarred ? Colors.amber.shade700 : cs.onSurface,
                        ),
                  ),
                  Text(
                    S.of(context, 'input_star_hint'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.outline,
                        ),
                  ),
                ],
              ),
            ),

            // activeColor removed in Flutter ≥ 3.31 —
            // replaced with activeThumbColor + activeTrackColor
            Switch.adaptive(
              value: isStarred,
              onChanged: onToggle,
              activeThumbColor: Colors.amber.shade600,
              activeTrackColor: Colors.amber.withValues(alpha: 0.35),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────
//  STAR ICON BUTTON — app bar trailing
// ───────────────────────────────────────────────────────────────────

class _StarIconButton extends StatelessWidget {
  final bool isStarred;
  final VoidCallback onTap;

  const _StarIconButton({required this.isStarred, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
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
          size: 26,
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────
//  DISCARD SHEET — Android bottom sheet
// ───────────────────────────────────────────────────────────────────

class _DiscardSheet extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _DiscardSheet({
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: cs.errorContainer.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: cs.error,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              S.of(context, 'discard_title'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              S.of(context, 'discard_body'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.outline,
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
                    label: S.of(context, 'discard_confirm'),
                    onPressed: onConfirm,
                    variant: AdaptiveButtonVariant.destructive,
                    fullWidth: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
