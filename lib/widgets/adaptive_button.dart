// ═══════════════════════════════════════════════════════════════════
//  ATHAR (أثر) — lib/widgets/adaptive_button.dart
//
//  Provides:
//  • AdaptiveButton        — primary / secondary / destructive / ghost
//  • AdaptiveIconButton    — icon-only, no label
//  • AdaptiveTextButton    — label-only, no background
//  • AdaptiveLoadingButton — spinner-inside-button during async ops
//
//  iOS    → CupertinoButton / CupertinoButton.filled
//  Android → FilledButton / OutlinedButton / TextButton (Material 3)
//
//  ✅ Fixed:
//  • CupertinoButton.minSize is double, NOT Size (Material-only API)
//  • secondary variant double-padding fixed via EdgeInsets.zero outer
//  • AdaptiveLoadingButton renders spinner directly, not a blank button
//  • CupertinoColors.destructiveRed resolved with .resolveFrom(context)
//  • AlwaysStoppedAnimation<Color> — generic type restored
//
//  ⚠️ This file must NOT import adaptive_scaffold.dart.
//     Zero shared classes exist between these two files.
// ═══════════════════════════════════════════════════════════════════

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ───────────────────────────────────────────────────────────────────
//  ENUMS
// ───────────────────────────────────────────────────────────────────

enum AdaptiveButtonVariant {
  primary, // filled background   — main CTA
  secondary, // outlined / no fill  — secondary action
  destructive, // red background      — delete / discard
  ghost, // fully flat          — tertiary action
}

enum AdaptiveButtonSize {
  small, // compact      — list tiles, chips
  medium, // default      — most use cases
  large, // full-width   — Save, Start, etc.
}

// ═══════════════════════════════════════════════════════════════════
//  ADAPTIVE BUTTON
// ═══════════════════════════════════════════════════════════════════

class AdaptiveButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AdaptiveButtonVariant variant;
  final AdaptiveButtonSize size;
  final Color? color;
  final bool fullWidth;
  final IconData? icon;

  const AdaptiveButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AdaptiveButtonVariant.primary,
    this.size = AdaptiveButtonSize.medium,
    this.color,
    this.fullWidth = false,
    this.icon,
  });

  // ── Named constructors ─────────────────────────────────────────

  const AdaptiveButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.color,
    this.fullWidth = false,
    this.icon,
    this.size = AdaptiveButtonSize.medium,
  }) : variant = AdaptiveButtonVariant.primary;

  const AdaptiveButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.color,
    this.fullWidth = false,
    this.icon,
    this.size = AdaptiveButtonSize.medium,
  }) : variant = AdaptiveButtonVariant.secondary;

  const AdaptiveButton.destructive({
    super.key,
    required this.label,
    required this.onPressed,
    this.color,
    this.fullWidth = false,
    this.icon,
    this.size = AdaptiveButtonSize.medium,
  }) : variant = AdaptiveButtonVariant.destructive;

  // ── Convenience getter ─────────────────────────────────────────
  bool get isPrimary => variant == AdaptiveButtonVariant.primary;

  // ── Haptic tap ─────────────────────────────────────────────────
  void _handleTap() {
    if (onPressed == null) return;
    Platform.isIOS
        ? HapticFeedback.lightImpact()
        : HapticFeedback.mediumImpact();
    onPressed!();
  }

  // ── Color resolution ───────────────────────────────────────────
  Color _resolvedColor(BuildContext context) {
    if (color != null) return color!;
    final cs = Theme.of(context).colorScheme;
    return switch (variant) {
      AdaptiveButtonVariant.primary => cs.primary,
      AdaptiveButtonVariant.secondary => cs.primary,
      AdaptiveButtonVariant.destructive => cs.error,
      AdaptiveButtonVariant.ghost => cs.primary,
    };
  }

  // ── Padding per size ───────────────────────────────────────────
  EdgeInsets _padding() => switch (size) {
        AdaptiveButtonSize.small =>
          const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        AdaptiveButtonSize.medium =>
          const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        AdaptiveButtonSize.large =>
          const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
      };

  // ── Font size per size ─────────────────────────────────────────
  double _fontSize() => switch (size) {
        AdaptiveButtonSize.small => 13,
        AdaptiveButtonSize.medium => 15,
        AdaptiveButtonSize.large => 16,
      };

  // ════════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) =>
      Platform.isIOS ? _buildCupertino(context) : _buildMaterial(context);

  // ── iOS ────────────────────────────────────────────────────────

  Widget _buildCupertino(BuildContext context) {
    final c = _resolvedColor(context);

    final Widget btn = switch (variant) {
      AdaptiveButtonVariant.primary => CupertinoButton.filled(
          onPressed: onPressed != null ? _handleTap : null,
          padding: _padding(),
          color: c,
          child: _child(isCupertino: true),
        ),

      // ✅ outer padding = zero so only the inner DecoratedBox
      // Padding applies — prevents the old double-padding bug.
      AdaptiveButtonVariant.secondary => CupertinoButton(
          onPressed: onPressed != null ? _handleTap : null,
          padding: EdgeInsets.zero,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: c.withValues(alpha: 0.6)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: _padding(),
              child: _child(isCupertino: true),
            ),
          ),
        ),
      AdaptiveButtonVariant.destructive => CupertinoButton(
          onPressed: onPressed != null ? _handleTap : null,
          padding: _padding(),
          color: CupertinoColors.destructiveRed,
          child: _child(isCupertino: true),
        ),
      AdaptiveButtonVariant.ghost => CupertinoButton(
          onPressed: onPressed != null ? _handleTap : null,
          padding: _padding(),
          child: _child(isCupertino: true),
        ),
    };

    return fullWidth ? SizedBox(width: double.infinity, child: btn) : btn;
  }

  // ── Android ────────────────────────────────────────────────────

  Widget _buildMaterial(BuildContext context) {
    final c = _resolvedColor(context);
    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
    final minSz = fullWidth ? const Size(double.infinity, 0) : Size.zero;

    final Widget btn = switch (variant) {
      AdaptiveButtonVariant.primary => FilledButton(
          onPressed: onPressed != null ? _handleTap : null,
          style: FilledButton.styleFrom(
            backgroundColor: c,
            padding: _padding(),
            minimumSize: minSz,
            textStyle:
                TextStyle(fontSize: _fontSize(), fontWeight: FontWeight.w600),
            shape: shape,
          ),
          child: _child(isCupertino: false),
        ),
      AdaptiveButtonVariant.secondary => OutlinedButton(
          onPressed: onPressed != null ? _handleTap : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: c,
            side: BorderSide(color: c.withValues(alpha: 0.6)),
            padding: _padding(),
            minimumSize: minSz,
            textStyle:
                TextStyle(fontSize: _fontSize(), fontWeight: FontWeight.w600),
            shape: shape,
          ),
          child: _child(isCupertino: false),
        ),
      AdaptiveButtonVariant.destructive => FilledButton(
          onPressed: onPressed != null ? _handleTap : null,
          style: FilledButton.styleFrom(
            backgroundColor: c,
            padding: _padding(),
            minimumSize: minSz,
            textStyle:
                TextStyle(fontSize: _fontSize(), fontWeight: FontWeight.w600),
            shape: shape,
          ),
          child: _child(isCupertino: false),
        ),
      AdaptiveButtonVariant.ghost => TextButton(
          onPressed: onPressed != null ? _handleTap : null,
          style: TextButton.styleFrom(
            foregroundColor: c,
            padding: _padding(),
            minimumSize: minSz,
            textStyle:
                TextStyle(fontSize: _fontSize(), fontWeight: FontWeight.w600),
            shape: shape,
          ),
          child: _child(isCupertino: false),
        ),
    };

    return fullWidth ? SizedBox(width: double.infinity, child: btn) : btn;
  }

  // ── Child: optional icon + label ──────────────────────────────

  Widget _child({required bool isCupertino}) {
    final textColor = switch (variant) {
      AdaptiveButtonVariant.primary => Colors.white,
      AdaptiveButtonVariant.destructive => Colors.white,
      _ => null, // inherit from theme
    };

    final text = Text(
      label,
      style: TextStyle(
        fontSize: _fontSize(),
        fontWeight: FontWeight.w600,
        color: isCupertino ? textColor : null,
      ),
    );

    if (icon == null) return text;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            size: _fontSize() + 2, color: isCupertino ? textColor : null),
        const SizedBox(width: 8),
        text,
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  ADAPTIVE ICON BUTTON
//  Icon-only. No label.
//  iOS     → CupertinoButton(padding: zero, minSize: double)
//  Android → IconButton (Material 3)
// ═══════════════════════════════════════════════════════════════════

class AdaptiveIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;
  final double size;

  const AdaptiveIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.color,
    this.size = 24,
  });

  void _handleTap() {
    if (onPressed == null) return;
    Platform.isIOS
        ? HapticFeedback.lightImpact()
        : HapticFeedback.mediumImpact();
    onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurface;

    if (Platform.isIOS) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        // ✅ CupertinoButton uses minSize (double), NOT minimumSize (Size).
        //    minimumSize is a Material-only API — passing Size crashes on iOS.
        minSize: size + 8,
        onPressed: onPressed != null ? _handleTap : null,
        child: Icon(icon, color: c, size: size),
      );
    }

    return IconButton(
      icon: Icon(icon, size: size),
      color: c,
      tooltip: tooltip,
      onPressed: onPressed != null ? _handleTap : null,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  ADAPTIVE TEXT BUTTON
//  Pure text link. No background. No border.
//  Used in dialogs, nav bars, and discard links.
// ═══════════════════════════════════════════════════════════════════

class AdaptiveTextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final bool isDestructive;

  const AdaptiveTextButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color,
    this.isDestructive = false,
  });

  void _handleTap() {
    if (onPressed == null) return;
    HapticFeedback.lightImpact();
    onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // ✅ .resolveFrom(context) ensures correct colour in dark mode.
    //    Without it CupertinoDynamicColor renders the wrong variant.
    final Color resolvedColor = isDestructive
        ? (Platform.isIOS
            ? CupertinoColors.destructiveRed.resolveFrom(context)
            : cs.error)
        : (color ?? cs.primary);

    if (Platform.isIOS) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed != null ? _handleTap : null,
        child: Text(
          label,
          style: TextStyle(
            color: resolvedColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return TextButton(
      onPressed: onPressed != null ? _handleTap : null,
      style: TextButton.styleFrom(
        foregroundColor: resolvedColor,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  ADAPTIVE LOADING BUTTON
//  Replaces label/icon with a platform spinner while [isLoading].
//  Disables onPressed automatically during loading — no double-tap.
//
//  ✅ Renders spinner directly inside button body.
//     Old version created a blank disabled AdaptiveButton during
//     loading so the spinner never appeared.
// ═══════════════════════════════════════════════════════════════════

class AdaptiveLoadingButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AdaptiveButtonVariant variant;
  final AdaptiveButtonSize size;
  final Color? color;
  final bool fullWidth;
  final IconData? icon;

  const AdaptiveLoadingButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.variant = AdaptiveButtonVariant.primary,
    this.size = AdaptiveButtonSize.medium,
    this.color,
    this.fullWidth = false,
    this.icon,
  });

  // ── Layout helpers ─────────────────────────────────────────────

  EdgeInsets _padding() => switch (size) {
        AdaptiveButtonSize.small =>
          const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        AdaptiveButtonSize.medium =>
          const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        AdaptiveButtonSize.large =>
          const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
      };

  double _fontSize() => switch (size) {
        AdaptiveButtonSize.small => 13.0,
        AdaptiveButtonSize.medium => 15.0,
        AdaptiveButtonSize.large => 16.0,
      };

  // ── Spinner colour ─────────────────────────────────────────────
  Color _spinnerColor(BuildContext context) {
    final isFilled = variant == AdaptiveButtonVariant.primary ||
        variant == AdaptiveButtonVariant.destructive;
    return isFilled
        ? Colors.white
        : (color ?? Theme.of(context).colorScheme.primary);
  }

  // ── Platform spinner ───────────────────────────────────────────
  Widget _spinner(BuildContext context) {
    final sc = _spinnerColor(context);
    if (Platform.isIOS) {
      return CupertinoActivityIndicator(color: sc);
    }
    return SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        // ✅ FIX: AlwaysStoppedAnimation → AlwaysStoppedAnimation<Color>
        valueColor: AlwaysStoppedAnimation<Color>(sc),
      ),
    );
  }

  // ── Label + icon ───────────────────────────────────────────────
  Widget _labelChild() => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: _fontSize() + 2, color: Colors.white),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: _fontSize(),
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      );

  // ════════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? Theme.of(context).colorScheme.primary;
    final child = isLoading ? _spinner(context) : _labelChild();
    final padding = _padding();
    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
    final minSz = fullWidth ? const Size(double.infinity, 0) : Size.zero;

    void onTap() {
      if (onPressed == null) return;
      Platform.isIOS
          ? HapticFeedback.lightImpact()
          : HapticFeedback.mediumImpact();
      onPressed!();
    }

    if (Platform.isIOS) {
      final btn = CupertinoButton.filled(
        onPressed: (isLoading || onPressed == null) ? null : onTap,
        padding: padding,
        color: resolvedColor,
        child: child,
      );
      return fullWidth ? SizedBox(width: double.infinity, child: btn) : btn;
    }

    return FilledButton(
      onPressed: (isLoading || onPressed == null) ? null : onTap,
      style: FilledButton.styleFrom(
        backgroundColor: resolvedColor,
        padding: padding,
        minimumSize: minSz,
        shape: shape,
        textStyle: TextStyle(
          fontSize: _fontSize(),
          fontWeight: FontWeight.w600,
        ),
      ),
      child: child,
    );
  }
}
