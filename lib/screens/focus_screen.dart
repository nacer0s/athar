// ═══════════════════════════════════════════════════════════════════
//  ATHAR (أثر) — lib/screens/focus_screen.dart
// ═══════════════════════════════════════════════════════════════════

import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../l10n/strings.dart';
import '../widgets/adaptive_button.dart';
import '../widgets/adaptive_scaffold.dart';
import 'input_screen.dart';

// ───────────────────────────────────────────────────────────────────
//  FOCUS SCREEN
// ───────────────────────────────────────────────────────────────────

class FocusScreen extends StatelessWidget {
  const FocusScreen({super.key});

  void _goToInput(BuildContext context) {
    final route = Platform.isIOS
        ? CupertinoPageRoute<void>(builder: (_) => const InputScreen())
        : MaterialPageRoute<void>(builder: (_) => const InputScreen());
    Navigator.of(context, rootNavigator: true).push(route);
  }

  @override
  Widget build(BuildContext context) {
    // ✅ FIX: context.watch() → context.watch<AppState>()
    final state = context.watch<AppState>();

    return AdaptiveScaffold(
      title: S.of(context, 'focus_title'),
      body: _FocusBody(
        state: state,
        onGoToInput: () => _goToInput(context),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────
//  FOCUS BODY — animated entry + full layout
// ───────────────────────────────────────────────────────────────────

class _FocusBody extends StatefulWidget {
  final AppState state;
  final VoidCallback onGoToInput;

  const _FocusBody({required this.state, required this.onGoToInput});

  @override
  State<_FocusBody> createState() => _FocusBodyState();
}

class _FocusBodyState extends State<_FocusBody>
    with SingleTickerProviderStateMixin {
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
      duration: const Duration(milliseconds: 600),
    );
    _entryFade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    // ✅ FIX: Tween → Tween<Offset>
    _entrySlide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final ringSize = (size.width * 0.74).clamp(220.0, 340.0);

    return FadeTransition(
      opacity: _entryFade,
      child: SlideTransition(
        position: _entrySlide,
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar: chip + streak ────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: _TopBar(state: widget.state),
              ),

              // ── Ring — takes available vertical space ─────────
              Expanded(
                child: Center(
                  child: _AnimatedTimerRing(
                    progress: widget.state.progress,
                    formattedTime: widget.state.formattedTime,
                    status: widget.state.status,
                    size: ringSize,
                    totalMinutes: widget.state.focusDurationMinutes,
                    elapsed: widget.state.focusDurationMinutes -
                        (widget.state.remainingSeconds ~/ 60),
                  ),
                ),
              ),

              // ── Status hint ───────────────────────────────────
              _StatusHint(status: widget.state.status),
              const SizedBox(height: 20),

              // ── Control buttons ───────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: _ControlRow(state: widget.state),
              ),
              const SizedBox(height: 16),

              // ── Completed banner (slides in from bottom) ──────
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 420),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, anim) => SlideTransition(
                  // ✅ FIX: Tween → Tween<Offset>
                  position: Tween<Offset>(
                    begin: const Offset(0, 1.0),
                    end: Offset.zero,
                  ).animate(anim),
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: widget.state.status == TimerStatus.completed
                    ? _CompletedBanner(
                        key: const ValueKey('banner'),
                        onLog: widget.onGoToInput,
                        onReset: widget.state.resetTimer,
                      )
                    : const SizedBox.shrink(key: ValueKey('no_banner')),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────
//  TOP BAR — session chip + today's session count
// ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final AppState state;
  const _TopBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isRunning = state.status == TimerStatus.running;
    final isAR = S.isRTL(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Session duration chip
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isRunning ? cs.primaryContainer : cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isRunning
                  ? cs.primary.withValues(alpha: 0.35)
                  : cs.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer_outlined,
                size: 13,
                color: isRunning ? cs.primary : cs.outline,
              ),
              const SizedBox(width: 5),
              Text(
                S.fmt(context, 'log_duration_label',
                    {'n': '${state.focusDurationMinutes}'}),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: isRunning ? cs.primary : cs.outline,
                      fontWeight:
                          isRunning ? FontWeight.bold : FontWeight.normal,
                    ),
              ),
            ],
          ),
        ),

        // Today's sessions badge
        if (state.totalSessions > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline_rounded,
                    size: 13, color: cs.outline),
                const SizedBox(width: 5),
                Text(
                  isAR
                      ? '${_todaySessions(state)} جلسة اليوم'
                      : '${_todaySessions(state)} today',
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: cs.outline),
                ),
              ],
            ),
          ),
      ],
    );
  }

  int _todaySessions(AppState state) =>
      state.logs.where((l) => l.isToday).length;
}

// ───────────────────────────────────────────────────────────────────
//  ANIMATED TIMER RING
// ───────────────────────────────────────────────────────────────────

class _AnimatedTimerRing extends StatefulWidget {
  final double progress;
  final String formattedTime;
  final TimerStatus status;
  final double size;
  final int totalMinutes;
  final int elapsed;

  const _AnimatedTimerRing({
    required this.progress,
    required this.formattedTime,
    required this.status,
    required this.size,
    required this.totalMinutes,
    required this.elapsed,
  });

  @override
  State<_AnimatedTimerRing> createState() => _AnimatedTimerRingState();
}

class _AnimatedTimerRingState extends State<_AnimatedTimerRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  // ✅ FIX: Animation → Animation<double>
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    // ✅ FIX: Tween → Tween<double>
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _syncPulse();
  }

  @override
  void didUpdateWidget(_AnimatedTimerRing old) {
    super.didUpdateWidget(old);
    if (old.status != widget.status) _syncPulse();
  }

  void _syncPulse() {
    if (widget.status == TimerStatus.running) {
      _pulseCtrl.repeat(reverse: true);
    } else {
      _pulseCtrl
        ..stop()
        ..animateTo(0, duration: const Duration(milliseconds: 300));
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Color _ringColor(ColorScheme cs) => switch (widget.status) {
        TimerStatus.running => cs.primary,
        TimerStatus.paused => cs.tertiary,
        TimerStatus.completed => const Color(0xFF43A047),
        TimerStatus.idle => cs.outlineVariant,
      };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ringColor = _ringColor(cs);

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, child) => Transform.scale(
        scale: _pulseAnim.value,
        child: child,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Outer glow ────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            width: widget.size * 0.92,
            height: widget.size * 0.92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: widget.status != TimerStatus.idle
                  ? [
                      BoxShadow(
                        color: ringColor.withValues(alpha: 0.13),
                        blurRadius: widget.size * 0.22,
                        spreadRadius: widget.size * 0.03,
                      ),
                    ]
                  : [],
            ),
          ),

          // ── Ring background fill ───────────────────────────────
          Container(
            width: widget.size * 0.82,
            height: widget.size * 0.82,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.surfaceContainerHigh.withValues(alpha: 0.5),
            ),
          ),

          // ── Arc + content ─────────────────────────────────────
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: _RingPainter(
                progress: widget.progress,
                ringColor: ringColor,
                trackColor: cs.surfaceContainerHighest,
                strokeWidth: widget.size * 0.042,
              ),
              child: Center(
                child: _RingContent(
                  formattedTime: widget.formattedTime,
                  status: widget.status,
                  size: widget.size,
                  ringColor: ringColor,
                  totalMinutes: widget.totalMinutes,
                  elapsed: widget.elapsed,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ring content ───────────────────────────────────────────────────

class _RingContent extends StatelessWidget {
  final String formattedTime;
  final TimerStatus status;
  final double size;
  final Color ringColor;
  final int totalMinutes;
  final int elapsed;

  const _RingContent({
    required this.formattedTime,
    required this.status,
    required this.size,
    required this.ringColor,
    required this.totalMinutes,
    required this.elapsed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // State label shown inside the ring (intentionally design-language,
    // not localized — mirrors common fitness/focus app convention)
    final stateLabel = switch (status) {
      TimerStatus.paused => 'PAUSED',
      TimerStatus.completed => 'DONE',
      TimerStatus.running => 'FOCUS',
      TimerStatus.idle => '',
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Optional state label ───────────────────────────────
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: stateLabel.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    stateLabel,
                    key: ValueKey(stateLabel),
                    style: TextStyle(
                      fontSize: size * 0.052,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.5,
                      color: ringColor.withValues(alpha: 0.8),
                    ),
                  ),
                )
              : SizedBox(
                  key: const ValueKey('no_label'),
                  height: size * 0.06,
                ),
        ),

        // ── MM:SS ──────────────────────────────────────────────
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: TextStyle(
            fontSize: size * 0.195,
            fontWeight: FontWeight.w200,
            letterSpacing: size * 0.010,
            height: 1.0,
            color: status == TimerStatus.completed
                ? const Color(0xFF43A047)
                : cs.onSurface,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          child: Text(formattedTime),
        ),

        const SizedBox(height: 6),

        // ── Elapsed / total indicator ──────────────────────────
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: status == TimerStatus.completed
              ? Icon(
                  Icons.check_circle_rounded,
                  key: const ValueKey('check'),
                  color: const Color(0xFF43A047),
                  size: size * 0.11,
                )
              : status != TimerStatus.idle
                  ? Text(
                      '$elapsed / $totalMinutes min',
                      key: ValueKey('$elapsed'),
                      style: TextStyle(
                        fontSize: size * 0.052,
                        color: cs.outline,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    )
                  : Text(
                      '$totalMinutes min',
                      key: const ValueKey('total'),
                      style: TextStyle(
                        fontSize: size * 0.052,
                        color: cs.outline,
                      ),
                    ),
        ),
      ],
    );
  }
}

// ── Ring CustomPainter ─────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double progress;
  final Color ringColor;
  final Color trackColor;
  final double strokeWidth;

  const _RingPainter({
    required this.progress,
    required this.ringColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - (strokeWidth / 2);
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

    if (progress > 0) {
      // Soft glow pass
      canvas.drawArc(
        rect,
        -pi / 2,
        2 * pi * progress,
        false,
        Paint()
          ..color = ringColor.withValues(alpha: 0.22)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth * 2.4
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );

      // Main arc
      canvas.drawArc(
        rect,
        -pi / 2,
        2 * pi * progress,
        false,
        Paint()
          ..color = ringColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );

      // Leading dot
      final angle = -pi / 2 + 2 * pi * progress;
      final dotPos = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      canvas.drawCircle(
        dotPos,
        strokeWidth * 0.62,
        Paint()..color = ringColor,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.ringColor != ringColor ||
      old.trackColor != trackColor ||
      old.strokeWidth != strokeWidth;
}

// ───────────────────────────────────────────────────────────────────
//  STATUS HINT — animated dot + crossfading label
// ───────────────────────────────────────────────────────────────────

class _StatusHint extends StatelessWidget {
  final TimerStatus status;
  const _StatusHint({required this.status});

  String _hintKey() => switch (status) {
        TimerStatus.idle => 'focus_idle_hint',
        TimerStatus.running => 'focus_running_hint',
        TimerStatus.paused => 'focus_paused_hint',
        TimerStatus.completed => 'focus_completed_hint',
      };

  Color _dotColor(ColorScheme cs) => switch (status) {
        TimerStatus.running => cs.primary,
        TimerStatus.paused => cs.tertiary,
        TimerStatus.completed => const Color(0xFF43A047),
        TimerStatus.idle => cs.outlineVariant,
      };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 380),
      transitionBuilder: (child, anim) =>
          FadeTransition(opacity: anim, child: child),
      child: Row(
        key: ValueKey(status),
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulsingDot(
              color: _dotColor(cs), active: status == TimerStatus.running),
          const SizedBox(width: 8),
          Text(
            S.of(context, _hintKey()),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.outline,
                  letterSpacing: 0.2,
                ),
          ),
        ],
      ),
    );
  }
}

// ── Pulsing dot for running state ──────────────────────────────────

class _PulsingDot extends StatefulWidget {
  final Color color;
  final bool active;
  const _PulsingDot({required this.color, required this.active});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  // ✅ FIX: Animation → Animation<double>
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    // ✅ FIX: Tween → Tween<double>
    _anim = Tween<double>(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    if (widget.active) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_PulsingDot old) {
    super.didUpdateWidget(old);
    if (widget.active && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.active) {
      _ctrl.stop();
      _ctrl.value = 1.0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(alpha: _anim.value),
          ),
        ),
      );
}

// ───────────────────────────────────────────────────────────────────
//  CONTROL ROW
// ───────────────────────────────────────────────────────────────────

class _ControlRow extends StatelessWidget {
  final AppState state;
  const _ControlRow({required this.state});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(scale: anim, child: child),
      ),
      child: _buildButtons(context),
    );
  }

  Widget _buildButtons(BuildContext context) {
    switch (state.status) {
      // ── Idle: single full-width Start ─────────────────────────
      case TimerStatus.idle:
        return SizedBox(
          key: const ValueKey('idle'),
          width: double.infinity,
          child: AdaptiveButton(
            label: S.of(context, 'btn_start'),
            onPressed: () {
              HapticFeedback.mediumImpact();
              state.startTimer();
            },
            size: AdaptiveButtonSize.large,
            fullWidth: true,
            icon: Icons.play_arrow_rounded,
          ),
        );

      // ── Running: Pause (wide) + Reset (narrow) ────────────────
      case TimerStatus.running:
        return Row(
          key: const ValueKey('running'),
          children: [
            Expanded(
              flex: 3,
              child: AdaptiveButton(
                label: S.of(context, 'btn_pause'),
                onPressed: state.pauseTimer,
                fullWidth: true,
                icon: Icons.pause_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: AdaptiveButton(
                label: S.of(context, 'btn_reset'),
                onPressed: state.resetTimer,
                variant: AdaptiveButtonVariant.secondary,
                fullWidth: true,
              ),
            ),
          ],
        );

      // ── Paused: Resume (wide) + Reset (narrow) ────────────────
      case TimerStatus.paused:
        return Row(
          key: const ValueKey('paused'),
          children: [
            Expanded(
              flex: 3,
              child: AdaptiveButton(
                label: S.of(context, 'btn_resume'),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  state.startTimer();
                },
                fullWidth: true,
                icon: Icons.play_arrow_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: AdaptiveButton(
                label: S.of(context, 'btn_reset'),
                onPressed: state.resetTimer,
                variant: AdaptiveButtonVariant.secondary,
                fullWidth: true,
              ),
            ),
          ],
        );

      // ── Completed: buttons replaced by banner below ───────────
      case TimerStatus.completed:
        return const SizedBox.shrink(key: ValueKey('completed'));
    }
  }
}

// ───────────────────────────────────────────────────────────────────
//  COMPLETED BANNER
// ───────────────────────────────────────────────────────────────────

class _CompletedBanner extends StatelessWidget {
  final VoidCallback onLog;
  final VoidCallback onReset;

  const _CompletedBanner({
    super.key,
    required this.onLog,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const green = Color(0xFF43A047);
    const greenDark = Color(0xFF2E7D32);
    const greenCTA = Color(0xFF388E3C);
    final isAR = S.isRTL(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
        decoration: BoxDecoration(
          color: green.withValues(alpha: 0.07),
          border: Border.all(
            color: green.withValues(alpha: 0.28),
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: green.withValues(alpha: 0.06),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Trophy row ────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: green.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  S.of(context, 'focus_completed_title'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: greenDark,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            Text(
              S.of(context, 'focus_completed_hint'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.outline,
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 16),

            // ── Log CTA ───────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: AdaptiveButton(
                label: S.of(context, 'btn_log_session'),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  onLog();
                },
                color: greenCTA,
                size: AdaptiveButtonSize.large,
                fullWidth: true,
                icon: Icons.edit_note_rounded,
              ),
            ),
            const SizedBox(height: 10),

            // ── Divider row ───────────────────────────────────
            Row(
              children: [
                Expanded(
                  child:
                      Divider(color: cs.outlineVariant.withValues(alpha: 0.4)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    isAR ? 'أو' : 'or',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: cs.outline),
                  ),
                ),
                Expanded(
                  child:
                      Divider(color: cs.outlineVariant.withValues(alpha: 0.4)),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // ── Reset ghost button ────────────────────────────
            AdaptiveButton(
              label: S.of(context, 'btn_reset'),
              onPressed: onReset,
              variant: AdaptiveButtonVariant.ghost,
              size: AdaptiveButtonSize.small,
            ),
          ],
        ),
      ),
    );
  }
}
