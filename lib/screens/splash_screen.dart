// ═══════════════════════════════════════════════════════════════════
// Athar (أثر) — lib/screens/splash_screen.dart
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const SplashScreen({super.key, required this.onComplete});

  @override
  // ✅ FIX: raw State → State<SplashScreen>
  State<SplashScreen> createState() => _SplashScreenState();
}

// ✅ FIX: raw State → State<SplashScreen>
class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  // ✅ FIX: raw Animation → Animation<double>
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    // Hide status/nav bars for a true full-screen splash
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // ✅ FIX: raw Tween → Tween<double>
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
      ),
    );

    // ✅ FIX: raw Tween → Tween<double>
    _scale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.70, curve: Curves.easeOutCubic),
      ),
    );

    _ctrl.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        // Restore system UI before handing off
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        widget.onComplete();
      });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ✅ FIX: bg matches SVG background so there is zero flash
    final bgColor = isDark ? const Color(0xFF323232) : const Color(0xFFFFFFFF);

    // ✅ FIX: select correct SVG variant
    final svgAsset =
        isDark ? 'assets/icons/splash_dm.svg' : 'assets/icons/splash_lm.svg';

    return Scaffold(
      backgroundColor: bgColor,
      body: FadeTransition(
        opacity: _fade,
        child: ScaleTransition(
          scale: _scale,
          // ✅ FIX: SVGs already contain a full background rect —
          //         render them edge-to-edge, not at 75% width
          child: SvgPicture.asset(
            svgAsset,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
} // ✅ FIX: missing closing brace added
