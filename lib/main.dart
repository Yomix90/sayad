import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' show DateFormat;

import 'l10n/app_localizations.dart';
import 'screens/forecast_table_screen.dart';
import 'screens/forum_screen.dart';
import 'screens/home_screen.dart';
import 'screens/map_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/tides_screen.dart';
import 'screens/tools_screen.dart';
import 'services/app_state.dart';
import 'theme.dart';
import 'widgets/line_icons.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Arabic screens show times and dates with 0-9 digits, as in Morocco.
  DateFormat.useNativeDigitsByDefaultFor('ar', false);
  final state = AppState();
  await state.load();
  runApp(AppScope(state: state, child: const SayadApp()));
  if (state.onboarded) state.locate();
}

/// Language actually shown: the user's choice, else the phone's language
/// when supported, else French.
String effectiveLanguage(AppState state) {
  final chosen = state.locale?.languageCode;
  if (chosen != null) return chosen;
  final system = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
  return AppState.languages.contains(system) ? system : 'fr';
}

class SayadApp extends StatelessWidget {
  const SayadApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final lang = effectiveLanguage(state);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (c) => AppLocalizations.of(c).appTitle,
      locale: Locale(lang),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: buildAppTheme(state.style, arabic: lang == 'ar'),
      home: const _Root(),
    );
  }
}

/// Animated loading page first, then the welcome flow or the tabs.
class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  bool _loading = true;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      child: _loading
          ? SplashScreen(
              onDone: () {
                if (mounted) setState(() => _loading = false);
              },
            )
          : state.onboarded
          ? const HomeShell()
          : const OnboardingScreen(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tabs = [
      ('fish', t.tabToday),
      ('waves', t.tides),
      ('pin', t.tabMap),
      ('cloud', t.tabForecast),
      ('chat', t.tabForum),
      ('grid', t.tabTools),
    ];
    return Scaffold(
      body: Column(
        children: [
          const AppHeader(child: BrandBar()),
          Expanded(
            child: PageBackground(
              child: IndexedStack(
                index: _index,
                children: const [
                  HomeScreen(),
                  TidesScreen(),
                  MapScreen(),
                  ForecastTableScreen(),
                  ForumScreen(),
                  ToolsScreen(),
                ],
              ),
            ),
          ),
          AppTabBar(
            items: tabs,
            index: _index,
            onTap: (i) => setState(() => _index = i),
          ),
        ],
      ),
    );
  }
}

/// Logo, app name, and the language and theme buttons.
class BrandBar extends StatelessWidget {
  const BrandBar({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final t = AppLocalizations.of(context);
    final state = AppScope.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    return Row(
      children: [
        const BrandMark(size: 44),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.appTitle.toUpperCase(),
                style: p
                    .title(19, color: p.headerInk)
                    .copyWith(
                      letterSpacing: lang == 'ar' ? 0 : 4.2,
                      height: 1.1,
                    ),
              ),
              Text(
                t.subtitle,
                style: TextStyle(fontSize: 13, color: p.headerMuted),
              ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          tooltip: t.language,
          onSelected: (code) => state.setLocale(Locale(code)),
          color: p.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(p.radiusS),
          ),
          itemBuilder: (_) => [
            for (final (code, name) in const [
              ('fr', 'Français'),
              ('ar', 'العربية'),
              ('en', 'English'),
            ])
              PopupMenuItem(
                value: code,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontWeight: code == lang
                              ? FontWeight.w800
                              : FontWeight.w500,
                          color: code == lang ? p.accentInk : p.text,
                        ),
                      ),
                    ),
                    Text(
                      code.toUpperCase(),
                      style: p.num(13, color: p.accentInk),
                    ),
                  ],
                ),
              ),
          ],
          child: _HeaderButton(
            children: [
              LineIcon('globe', size: 20, color: p.headerInk),
              const SizedBox(width: 6),
              Text(lang.toUpperCase(), style: p.num(13, color: p.headerInk)),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Tooltip(
          message: t.changeTheme,
          child: GestureDetector(
            onTap: () =>
                state.setStyle(p.classic ? AppStyle.modern : AppStyle.classic),
            child: _HeaderButton(
              children: [
                LineIcon(
                  p.classic ? 'sun' : 'compass',
                  size: 20,
                  color: p.headerInk,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: p.classic
              ? p.accent.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.22),
        ),
        color: p.classic
            ? p.accent.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: children,
      ),
    );
  }
}

/// Rounded square (modern) or gilded circle (classic) with the fish logo.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 44});
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: p.classic ? Colors.transparent : const Color(0x3800B4D8),
        shape: p.classic ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: p.classic ? null : BorderRadius.circular(size * 0.32),
        border: Border.all(
          color: p.classic ? p.accent : Colors.white.withValues(alpha: 0.28),
          width: p.classic ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset('assets/brand/emblem.png', fit: BoxFit.cover),
    );
  }
}

/// Bottom navigation with a sliding indicator on top of the active tab.
class AppTabBar extends StatelessWidget {
  const AppTabBar({
    super.key,
    required this.items,
    required this.index,
    required this.onTap,
  });

  final List<(String, String)> items;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: p.navBg,
        border: Border(
          top: p.classic
              ? BorderSide(color: p.accent, width: 2)
              : BorderSide(color: p.text.withValues(alpha: 0.08)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  child: SizedBox(
                    height: 66,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: FractionallySizedBox(
                            widthFactor: 0.48,
                            child: AnimatedScale(
                              duration: const Duration(milliseconds: 250),
                              scale: i == index ? 1 : 0,
                              child: Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  color: p.accent,
                                  borderRadius: const BorderRadius.vertical(
                                    bottom: Radius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        AnimatedSlide(
                          duration: const Duration(milliseconds: 200),
                          offset: Offset(0, i == index ? -0.04 : 0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              LineIcon(
                                items[i].$1,
                                size: 23,
                                color: i == index ? p.navActive : p.navInk,
                              ),
                              const SizedBox(height: 3),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  items[i].$2,
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: i == index ? p.navActive : p.navInk,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
