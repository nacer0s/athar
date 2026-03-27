// ═══════════════════════════════════════════════════════════════════
//  Athar (أثر) — main.dart
// ═══════════════════════════════════════════════════════════════════

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'l10n/strings.dart';
import 'models/focus_log.dart';
import 'screens/focus_screen.dart';
import 'screens/log_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart'; // ✅ FIX: missing import added
import 'screens/stats_screen.dart';

// ───────────────────────────────────────────────────────────────────
//  BOOTSTRAP
// ───────────────────────────────────────────────────────────────────

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── 1. intl locale symbol tables ──────────────────────────────
  await initializeDateFormatting();

  // ── 2. Hive ────────────────────────────────────────────────────
  await Hive.initFlutter();
  Hive.registerAdapter(FocusLogAdapter());
  await Hive.openBox<FocusLog>('focus_logs');
  await Hive.openBox<dynamic>('prefs');

  // ── 3. AppState ────────────────────────────────────────────────
  final appState = AppState();
  await appState.init();

  // ── 4. Run app ─────────────────────────────────────────────────
  runApp(
    ChangeNotifierProvider<AppState>.value(
      value: appState,
      child: const AtharApp(),
    ),
  );
}

// ───────────────────────────────────────────────────────────────────
//  ROOT APP WIDGET
// ───────────────────────────────────────────────────────────────────

class AtharApp extends StatelessWidget {
  const AtharApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isAR = state.locale.languageCode == 'ar';

    return MaterialApp(
      title: 'Athar',
      debugShowCheckedModeBanner: false,
      themeMode: state.themeMode,

      // ── Themes ────────────────────────────────────────────────
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF4A90D9),
        brightness: Brightness.light,
        fontFamily: 'Cairo',
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF4A90D9),
        brightness: Brightness.dark,
        fontFamily: 'Cairo',
      ),

      // ── Locale ────────────────────────────────────────────────
      locale: state.locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],

      // ── RTL wrapper ───────────────────────────────────────────
      builder: (context, child) => Directionality(
        textDirection: isAR ? TextDirection.rtl : TextDirection.ltr,
        child: child!,
      ),

      // ✅ FIX: home was MainShell — now points to AppRoot so the
      //         splash runs before the main shell is shown
      home: const AppRoot(),
    );
  }
}

// ───────────────────────────────────────────────────────────────────
//  APP ROOT — Splash → Main Shell gate
// ───────────────────────────────────────────────────────────────────

// ✅ FIX: AppRoot StatefulWidget was completely missing — only its
//         State existed, which caused a compile error
class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  bool _splashDone = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: _splashDone
          ? const MainShell(key: ValueKey('main'))
          : SplashScreen(
              key: const ValueKey('splash'),
              onComplete: () => setState(() => _splashDone = true),
            ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────
//  MAIN SHELL — Adaptive bottom navigation
// ───────────────────────────────────────────────────────────────────

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const List<Widget> _screens = [
    FocusScreen(),
    LogScreen(),
    StatsScreen(),
    SettingsScreen(),
  ];

  static const List<IconData> _icons = [
    Icons.timer_outlined,
    Icons.list_alt_outlined,
    Icons.bar_chart_outlined,
    Icons.settings_outlined,
  ];

  static const List<IconData> _iconsActive = [
    Icons.timer_rounded,
    Icons.list_alt_rounded,
    Icons.bar_chart_rounded,
    Icons.settings_rounded,
  ];

  List<String> _labels(BuildContext context) => [
        S.of(context, 'focus'),
        S.of(context, 'logs'),
        S.of(context, 'stats'),
        S.of(context, 'settings'),
      ];

  // ── iOS ───────────────────────────────────────────────────────

  Widget _buildIOS(BuildContext context) {
    final labels = _labels(context);

    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: List.generate(
          4,
          (i) => BottomNavigationBarItem(
            icon: Icon(_icons[i]),
            activeIcon: Icon(_iconsActive[i]),
            label: labels[i],
          ),
        ),
      ),
      tabBuilder: (_, index) => CupertinoTabView(
        builder: (_) => _screens[index],
      ),
    );
  }

  // ── Android ───────────────────────────────────────────────────

  Widget _buildAndroid(BuildContext context) {
    final labels = _labels(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        animationDuration: const Duration(milliseconds: 300),
        destinations: List.generate(
          4,
          (i) => NavigationDestination(
            icon: Icon(_icons[i]),
            selectedIcon: Icon(
              _iconsActive[i],
              color: cs.onSecondaryContainer,
            ),
            label: labels[i],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) =>
      Platform.isIOS ? _buildIOS(context) : _buildAndroid(context);
}
