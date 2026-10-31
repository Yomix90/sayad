import 'package:flutter/material.dart';

import '../theme.dart';

/// Layout for pages pushed on top of the tabs: themed header with a back
/// button and title, then the page body.
class SubPage extends StatelessWidget {
  const SubPage({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
    this.floatingActionButton,
  });

  final String title;
  final Widget body;
  final List<Widget> actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Scaffold(
      floatingActionButton: floatingActionButton,
      body: Column(children: [
        AppHeader(
          bottomPadding: p.classic ? 12 : 24,
          child: Row(children: [
            if (Navigator.of(context).canPop())
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: Icon(Icons.arrow_back, color: p.headerInk),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: p.title(19, color: p.headerInk)),
            ),
            ...actions,
          ]),
        ),
        Expanded(child: PageBackground(child: body)),
      ]),
    );
  }
}
