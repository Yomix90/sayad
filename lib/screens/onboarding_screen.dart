import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/app_state.dart';
import '../theme.dart';
import 'city_picker.dart';

/// First launch: language, fishing region (or GPS), then visual style.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.replay = false});

  /// Opened again from the settings: close instead of finishing.
  final bool replay;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 1;
  /// Set once a town or GPS was picked; otherwise GPS is tried at the end.
  bool _picked = false;

  Future<void> _finish() async {
    final state = AppScope.of(context);
    final navigator = Navigator.of(context);
    if (!_picked) state.locate();
    if (widget.replay) {
      navigator.pop();
    } else {
      await state.finishOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final t = AppLocalizations.of(context);
    return Scaffold(
      body: PageBackground(
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(children: [
                Visibility(
                  visible: _step > 1,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: IconButton(
                    onPressed: () => setState(() => _step--),
                    icon: Icon(Icons.arrow_back, color: p.text),
                  ),
                ),
                Expanded(
                  child: Text(t.stepOf(_step, 3),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: p.muted)),
                ),
                IconButton(
                  tooltip: t.later,
                  onPressed: _finish,
                  icon: Icon(Icons.close, color: p.text),
                ),
              ]),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  Center(
                    child: Container(
                      width: 132,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: const Color(0xFF082642),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: p.shadow,
                      ),
                      child: Image.asset('assets/brand/logo_full.png'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(t.subtitle, style: TextStyle(color: p.muted)),
                  ),
                  const SizedBox(height: 12),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: KeyedSubtree(
                      key: ValueKey(_step),
                      child: switch (_step) {
                        1 => _languageStep(context),
                        2 => _regionStep(context),
                        _ => _styleStep(context),
                      },
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _step < 3 ? () => setState(() => _step++) : _finish,
                  child: Text(_step < 3 ? t.continueLabel : t.start),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (var i = 1; i <= 3; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3.5),
                    width: i <= _step ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i <= _step ? p.accent : p.border,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _heading(BuildContext context, String title, String sub) {
    final p = Palette.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 12),
      Text(title, style: p.title(19)),
      const SizedBox(height: 4),
      Text(sub, style: TextStyle(fontSize: 15, color: p.muted, height: 1.45)),
      const SizedBox(height: 14),
    ]);
  }

  Widget _languageStep(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = AppScope.of(context);
    final current = Localizations.localeOf(context).languageCode;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _heading(context, t.chooseLanguage, t.chooseLanguageSub),
      for (final (code, name) in const [
        ('fr', 'Français'),
        ('ar', 'العربية'),
        ('en', 'English'),
      ])
        OptionTile(
          selected: current == code,
          leading: _Flag(code.toUpperCase()),
          title: name,
          onTap: () => state.setLocale(Locale(code)),
        ),
    ]);
  }

  Widget _regionStep(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _heading(context, t.chooseRegion, t.chooseRegionSub),
      CityPicker(onPicked: () => setState(() => _picked = true)),
    ]);
  }

  Widget _styleStep(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = AppScope.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _heading(context, t.chooseStyle, t.chooseStyleSub),
      OptionTile(
        selected: state.style == AppStyle.modern,
        leading: const _StyleSwatch(Palette.modern),
        title: t.styleModern,
        subtitle: t.styleModernSub,
        onTap: () => state.setStyle(AppStyle.modern),
      ),
      OptionTile(
        selected: state.style == AppStyle.classic,
        leading: const _StyleSwatch(Palette.classicPalette),
        title: t.styleClassic,
        subtitle: t.styleClassicSub,
        onTap: () => state.setStyle(AppStyle.classic),
      ),
    ]);
  }
}

/// Selectable row with a radio dot, as in the welcome flow and settings.
class OptionTile extends StatelessWidget {
  const OptionTile({
    super.key,
    required this.selected,
    required this.leading,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final bool selected;
  final Widget leading;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: selected ? p.surface2 : p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(p.radiusS),
          side: BorderSide(color: selected ? p.accent : p.border, width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(p.radiusS),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(children: [
                leading,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: p.text)),
                        if (subtitle != null)
                          Text(subtitle!,
                              style: TextStyle(fontSize: 13, color: p.muted)),
                      ]),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 21,
                  height: 21,
                  padding: const EdgeInsets.all(3.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: selected ? p.accent : p.border, width: 2),
                  ),
                  child: selected
                      ? DecoratedBox(
                          decoration: BoxDecoration(
                              color: p.accent, shape: BoxShape.circle))
                      : null,
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _Flag extends StatelessWidget {
  const _Flag(this.code);
  final String code;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: p.border),
      ),
      child: Text(code, style: p.num(13, color: p.accentInk)),
    );
  }
}

/// Small preview of a style: its header colours and card.
class _StyleSwatch extends StatelessWidget {
  const _StyleSwatch(this.palette);
  final Palette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
        color: palette.bg,
      ),
      child: Column(children: [
        Container(height: 18, decoration: BoxDecoration(gradient: palette.header)),
        Expanded(
          child: Center(
            child: Container(
              width: 28,
              height: 14,
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: palette.accent),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
