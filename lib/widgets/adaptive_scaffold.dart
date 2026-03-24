// ═══════════════════════════════════════════════════════════════════
//  ATHAR (أثر) — lib/widgets/adaptive_scaffold.dart
//
//  Provides:
//  • AdaptiveScaffold       — main per-screen scaffold
//  • AdaptiveSliverScaffold — for screens with CustomScrollView
//  • AdaptiveBackButton     — platform-correct back chevron
//
//  iOS    → CupertinoPageScaffold
//           Standard : CupertinoNavigationBar
//           Large    : CupertinoSliverNavigationBar (iOS-11 expand)
//  Android → Material 3 Scaffold + AppBar / SliverAppBar.large
//
//  ✅ Fixed:
//  • Global* localisation delegates (not Default*) applied upstream
//  • _ActionsRow uses EdgeInsetsDirectional — RTL-safe spacing
//  • bottomBar on iOS sits inside SafeArea Column, not as a sheet
//  • largeTitleIOS wraps non-ScrollView bodies in SingleChildScrollView
//  • buildAction() static helper added for screen action buttons
//  • List → List<Widget> restored on all four raw fields
//
//  ⚠️ This file must NOT contain AdaptiveButton / AdaptiveButtonVariant
//     / AdaptiveButtonSize / AdaptiveLoadingButton / AdaptiveTextButton.
//     Those live exclusively in adaptive_button.dart.
// ═══════════════════════════════════════════════════════════════════

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════
//  ADAPTIVE SCAFFOLD
// ═══════════════════════════════════════════════════════════════════

class AdaptiveScaffold extends StatelessWidget {
  // ── Required ──────────────────────────────────────────────────
  final String title;
  final Widget body;

  // ── Navigation bar ────────────────────────────────────────────
  /// Trailing action widgets placed in the nav bar.
  /// Pass [AdaptiveScaffold.buildAction] results here for correct
  /// platform rendering (CupertinoButton on iOS / IconButton on Android).
  // ✅ FIX: List? → List<Widget>?
  final List<Widget>? actions;

  /// Overrides the default back / leading widget.
  final Widget? leading;

  // ── iOS-specific ──────────────────────────────────────────────
  /// Uses CupertinoSliverNavigationBar — iOS-11 collapsible large title.
  /// [body] MUST be a ScrollView when true; plain widgets are
  /// auto-wrapped in SingleChildScrollView so the header can collapse.
  final bool largeTitleIOS;

  // ── Android-specific ──────────────────────────────────────────
  /// FAB rendered in Scaffold.floatingActionButton. Ignored on iOS.
  final Widget? floatingActionButton;

  // ── Shared ────────────────────────────────────────────────────
  /// Fixed widget below the body.
  /// Android → Scaffold.bottomNavigationBar (pushed down by keyboard,
  ///           never overlaps body like a bottomSheet would).
  /// iOS     → placed inside a SafeArea Column below the body.
  final Widget? bottomBar;

  final bool resizeToAvoidBottomInset;
  final Color? backgroundColor;

  const AdaptiveScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.leading,
    this.largeTitleIOS = false,
    this.floatingActionButton,
    this.bottomBar,
    this.resizeToAvoidBottomInset = true,
    this.backgroundColor,
  });

  // ════════════════════════════════════════════════════════════════
  //  STATIC HELPER — platform action button
  //  Used by screens that pass widgets into [actions].
  //  iOS     → CupertinoButton (zero padding, correct hit area)
  //  Android → IconButton (Material 3 ink + tooltip)
  // ════════════════════════════════════════════════════════════════

  static Widget buildAction({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onPressed,
    String? tooltip,
    Color? color,
  }) {
    final resolvedColor = color ?? Theme.of(context).colorScheme.onSurface;

    if (Platform.isIOS) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        // ✅ minSize is double on CupertinoButton — NOT Size (Material API)
        minSize: 32,
        onPressed: onPressed,
        child: Icon(icon, size: 22, color: resolvedColor),
      );
    }

    return IconButton(
      icon: Icon(icon),
      color: resolvedColor,
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) =>
      Platform.isIOS ? _buildIOS(context) : _buildAndroid(context);

  // ─────────────────────────────────────────────────────────────
  //  iOS
  // ─────────────────────────────────────────────────────────────

  Widget _buildIOS(BuildContext context) =>
      largeTitleIOS ? _buildIOSLargeTitle(context) : _buildIOSStandard(context);

  // Standard — fixed-height nav bar
  Widget _buildIOSStandard(BuildContext context) {
    return CupertinoPageScaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      backgroundColor: backgroundColor,
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        leading: leading,
        trailing: actions != null && actions!.isNotEmpty
            ? _ActionsRow(actions: actions!)
            : null,
        // Semi-transparent so content scrolls behind the bar
        backgroundColor: CupertinoColors.systemBackground
            .resolveFrom(context)
            .withValues(alpha: 0.92),
        border: Border(
          bottom: BorderSide(
            color: CupertinoColors.systemGrey5.resolveFrom(context),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        // top: false — CupertinoPageScaffold handles top inset via nav bar
        top: false,
        child: Column(
          children: [
            Expanded(child: body),
            // bottomBar inside SafeArea — above home indicator,
            // consistent with Android bottomNavigationBar placement.
            if (bottomBar != null) bottomBar!,
          ],
        ),
      ),
    );
  }

  // Large title — iOS-11 collapsible nav bar
  Widget _buildIOSLargeTitle(BuildContext context) {
    // NestedScrollView requires a ScrollView as its inner body.
    // Wrap plain widgets so the header can still collapse on scroll.
    final scrollableBody = _ensureScrollable(body);

    return CupertinoPageScaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      backgroundColor: backgroundColor,
      child: Column(
        children: [
          Expanded(
            child: NestedScrollView(
              headerSliverBuilder: (context, _) => [
                CupertinoSliverNavigationBar(
                  largeTitle: Text(title),
                  leading: leading,
                  trailing: actions != null && actions!.isNotEmpty
                      ? _ActionsRow(actions: actions!)
                      : null,
                  backgroundColor: CupertinoColors.systemBackground
                      .resolveFrom(context)
                      .withValues(alpha: 0.92),
                  border: Border(
                    bottom: BorderSide(
                      color: CupertinoColors.systemGrey5.resolveFrom(context),
                      width: 0.5,
                    ),
                  ),
                ),
              ],
              body: scrollableBody,
            ),
          ),
          if (bottomBar != null) bottomBar!,
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Android — Material 3
  // ─────────────────────────────────────────────────────────────

  Widget _buildAndroid(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        scrolledUnderElevation: 1,
        shadowColor: cs.shadow.withValues(alpha: 0.08),
        leading: leading,
        actions: actions,
      ),
      floatingActionButton: floatingActionButton,
      // ✅ bottomNavigationBar — NOT bottomSheet.
      //    bottomSheet floats over content like a modal and clashes with
      //    the keyboard. bottomNavigationBar is pushed down by the IME
      //    and never overlaps the body.
      bottomNavigationBar: bottomBar,
      body: body,
    );
  }

  // ── Scrollable guard ───────────────────────────────────────────
  // NestedScrollView needs a ScrollView body to connect the sliver
  // header collapse animation. Wrap plain widgets transparently.
  static Widget _ensureScrollable(Widget w) {
    if (w is ScrollView) return w;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: w,
    );
  }
}

// ───────────────────────────────────────────────────────────────────
//  ACTIONS ROW HELPER
//  Packs multiple trailing action widgets into a compact Row.
//  EdgeInsetsDirectional.only(start: 4) flips automatically in RTL
//  so spacing is always on the correct side in AR and EN layouts.
// ───────────────────────────────────────────────────────────────────

class _ActionsRow extends StatelessWidget {
  // ✅ FIX: List → List<Widget>
  final List<Widget> actions;
  const _ActionsRow({required this.actions});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: actions
          .map(
            (a) => Padding(
              // start = left in LTR, right in RTL — auto-flipped
              padding: const EdgeInsetsDirectional.only(start: 4),
              child: a,
            ),
          )
          .toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  ADAPTIVE SLIVER SCAFFOLD
//  For screens that own a CustomScrollView with mixed sliver sections
//  (SliverList + SliverGrid, sticky headers, etc.)
// ═══════════════════════════════════════════════════════════════════

class AdaptiveSliverScaffold extends StatelessWidget {
  final String title;
  // ✅ FIX: List → List<Widget>
  final List<Widget> slivers;
  // ✅ FIX: List? → List<Widget>?
  final List<Widget>? actions;
  final Widget? leading;
  final Color? backgroundColor;

  const AdaptiveSliverScaffold({
    super.key,
    required this.title,
    required this.slivers,
    this.actions,
    this.leading,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoPageScaffold(
        backgroundColor: backgroundColor,
        child: CustomScrollView(
          slivers: [
            CupertinoSliverNavigationBar(
              largeTitle: Text(title),
              leading: leading,
              trailing: actions != null && actions!.isNotEmpty
                  ? _ActionsRow(actions: actions!)
                  : null,
              backgroundColor: CupertinoColors.systemBackground
                  .resolveFrom(context)
                  .withValues(alpha: 0.92),
              border: Border(
                bottom: BorderSide(
                  color: CupertinoColors.systemGrey5.resolveFrom(context),
                  width: 0.5,
                ),
              ),
            ),
            ...slivers,
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text(title),
            leading: leading,
            actions: actions,
            centerTitle: false,
            pinned: true,
            scrolledUnderElevation: 1,
          ),
          ...slivers,
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  ADAPTIVE BACK BUTTON
//  Platform-correct back control for use when [leading] is overridden
//  (e.g. modal screens that need a Close × button alongside swipe-back).
//
//  iOS     → CupertinoIcons.back chevron (CupertinoButton, zero padding)
//  Android → Icons.arrow_back_rounded   (IconButton, Material ink)
// ═══════════════════════════════════════════════════════════════════

class AdaptiveBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? color;

  const AdaptiveBackButton({super.key, this.onPressed, this.color});

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ??
        (Platform.isIOS
            ? CupertinoColors.activeBlue
            : Theme.of(context).colorScheme.onSurface);

    if (Platform.isIOS) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        // ✅ minSize is double — NOT Size
        minSize: 32,
        onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
        child: Icon(
          CupertinoIcons.back,
          color: resolvedColor,
          size: 28,
        ),
      );
    }

    return IconButton(
      icon: Icon(
        Icons.arrow_back_rounded,
        color: resolvedColor,
      ),
      onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
    );
  }
}
