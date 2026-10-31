import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Thin line icons (24×24) and guide illustrations (64×64), drawn with
/// `currentColor` so they take the colour passed to [LineIcon].
const _icons = <String, String>{
  'fish': '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M6.8 12c2.4-3.7 6.3-5.4 9.7-4 1.9.8 3.3 2.3 4.5 4-1.2 1.7-2.6 3.2-4.5 4-3.4 1.4-7.3-.3-9.7-4Z"/><path d="M6.8 12 2.8 8.8v6.4L6.8 12Z"/><circle cx="16.2" cy="11" r=".7" fill="currentColor" stroke="none"/></svg>',
  'waves': '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"><path d="M2 7.5c2-2.4 4-2.4 6 0s4 2.4 6 0 4-2.4 6 0M2 12.5c2-2.4 4-2.4 6 0s4 2.4 6 0 4-2.4 6 0M2 17.5c2-2.4 4-2.4 6 0s4 2.4 6 0 4-2.4 6 0"/></svg>',
  'pin': '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M12 21.2s-7-5.9-7-11a7 7 0 0 1 14 0c0 5.1-7 11-7 11Z"/><circle cx="12" cy="10" r="2.6"/></svg>',
  'cloud': '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M6.3 15a4 4 0 1 1 .7-7.95A5.4 5.4 0 0 1 17.5 9a3.4 3.4 0 0 1-.6 6.7H7"/><path d="M4 19h9m-6 3h4"/></svg>',
  'book': '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M4 5.5A2.5 2.5 0 0 1 6.5 3H20v15H6.5A2.5 2.5 0 0 0 4 20.5V5.5Z"/><path d="M4 18.5A2.5 2.5 0 0 1 6.5 16H20"/><path d="M9 7.5h6"/></svg>',
  'wind': '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"><path d="M3 8h9.3a2.4 2.4 0 1 0-2.3-3.1M3 12.5h13.6a2.4 2.4 0 1 1-2.3 3.1M3 17h7.2"/></svg>',
  'thermo': '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"><path d="M10 4a2 2 0 1 1 4 0v9.2a4.2 4.2 0 1 1-4 0V4Z"/><path d="M12 9.5V15"/><circle cx="12" cy="17.2" r="1.5" fill="currentColor" stroke="none"/></svg>',
  'gauge': '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"><path d="M4 15a8 8 0 1 1 16 0"/><path d="M12 15l3.6-4.4"/><path d="M5.5 19.5h13"/></svg>',
  'sun': '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"><circle cx="12" cy="12" r="4"/><path d="M12 2.5v2.2M12 19.3v2.2M2.5 12h2.2M19.3 12h2.2M5 5l1.6 1.6M17.4 17.4 19 19M19 5l-1.6 1.6M6.6 17.4 5 19"/></svg>',
  'moon': '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linejoin="round"><path d="M20 13.6A8.1 8.1 0 0 1 10.4 4 8.1 8.1 0 1 0 20 13.6Z"/></svg>',
  'check': '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="m5 12.5 4.5 4.5L19 7.5"/></svg>',
  'nav': '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linejoin="round"><path d="m4.5 11 15.5-6.8L13.2 20l-2.3-6.3L4.5 11Z"/></svg>',
  'bookmark': '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linejoin="round"><path d="M7 3.5h10a1 1 0 0 1 1 1V21l-6-3.8L6 21V4.5a1 1 0 0 1 1-1Z"/></svg>',
  'store': '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M4.5 9 5.8 4h12.4L19.5 9M5 9v11h14V9M9.5 20v-5.5h5V20M4.5 9h15"/></svg>',
  'star': '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linejoin="round"><path d="m12 3.5 2.6 5.3 5.9.9-4.3 4.1 1 5.8L12 16.9l-5.2 2.7 1-5.8-4.3-4.1 5.9-.9L12 3.5Z"/></svg>',
  'globe': '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7"><circle cx="12" cy="12" r="8.5"/><path d="M3.5 12h17M12 3.5c2.5 2.3 3.8 5.2 3.8 8.5s-1.3 6.2-3.8 8.5c-2.5-2.3-3.8-5.2-3.8-8.5s1.3-6.2 3.8-8.5Z"/></svg>',
  'compass': '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linejoin="round"><circle cx="12" cy="12" r="8.8"/><path d="m14.9 9.1-1.9 5.7-3.9 1.9 1.9-5.7 3.9-1.9Z"/></svg>',
  'cross': '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"><circle cx="12" cy="12" r="7"/><path d="M12 2.8v3M12 18.2v3M2.8 12h3M18.2 12h3"/><circle cx="12" cy="12" r="1.4" fill="currentColor" stroke="none"/></svg>',
  'anchor': '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"><circle cx="12" cy="5.2" r="2.2"/><path d="M12 7.4V21M5 12H2.8a9.2 9.2 0 0 0 18.4 0H19"/></svg>',
  'clock': '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"><circle cx="12" cy="12" r="8.5"/><path d="M12 7v5l3.2 2"/></svg>',
  'info': '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"><circle cx="12" cy="12" r="8.5"/><path d="M12 11v5.5M12 7.6h.01"/></svg>',
  'up': '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M12 19V5m0 0-5.5 5.5M12 5l5.5 5.5"/></svg>',
  'down': '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M12 5v14m0 0 5.5-5.5M12 19l-5.5-5.5"/></svg>',
  'grid': '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linejoin="round"><rect x="4" y="4" width="6.5" height="6.5" rx="1.6"/><rect x="13.5" y="4" width="6.5" height="6.5" rx="1.6"/><rect x="4" y="13.5" width="6.5" height="6.5" rx="1.6"/><rect x="13.5" y="13.5" width="6.5" height="6.5" rx="1.6"/></svg>',
  // Guide illustrations: knots.
  'k-bowline': '<svg viewBox="0 0 64 64" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"><circle cx="32" cy="42" r="13"/><path d="M32 29V6"/><path d="M32 29c-9 3-11.5 9-6 13.5M32 29c6 2 8 6 6.5 10"/><path d="M32 6c1.5-2 4-2.5 6-1.5"/></svg>',
  'k-palomar': '<svg viewBox="0 0 64 64" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"><path d="M28 8v22a10 10 0 1 0 13 9.5c0-6-5.5-9.5-13-9.5"/><path d="M28 30l-3.5-1.5M41 39.5l4-2"/><ellipse cx="30" cy="22" rx="8.5" ry="4.5" transform="rotate(-8 30 22)"/><circle cx="28" cy="8" r="2.6"/></svg>',
  'k-surgeon': '<svg viewBox="0 0 64 64" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"><path d="M6 22c14 0 24 20 52 20M6 42c14 0 24-20 52-20"/><path d="M26 26.5 38 30M26 30l12 3.5M26 33.5 38 37"/></svg>',
  'k-eight': '<svg viewBox="0 0 64 64" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"><path d="M32 9c-9 0-9 13.5 0 17 9 3.5 9 17 0 17s-9-13.5 0-17c9-3.5 9-17 0-17Z"/><path d="M32 43v9M32 9 36 4"/></svg>',
  // Guide illustrations: hooks.
  'h-circle': '<svg viewBox="0 0 64 64" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><circle cx="30" cy="8.5" r="3"/><path d="M30 11.5v14c0 13 8 21 15 21 6.5 0 10-6 10-11 0-4-2.5-6.5-5.5-6.5"/><path d="M49.5 29l-4.5-2 5-3.5"/></svg>',
  'h-aberdeen': '<svg viewBox="0 0 64 64" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><circle cx="29" cy="6.5" r="3"/><path d="M29 9.5v33c0 9 6 13 11.5 13 5 0 8.5-3.5 8.5-7.5 0-3-1.5-4.5-3.5-4.5"/><path d="M45.5 43.5l-4-1.5 4.5-3"/></svg>',
  'h-octopus': '<svg viewBox="0 0 64 64" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><circle cx="26.5" cy="10" r="3"/><path d="M28.5 12.5c2 3 3.5 6 3.5 10v16c0 10 7 15 13 15 5.5 0 9-4 9-8 0-3-2-5-4.5-5"/><path d="M49.5 40.5l-4.5-1.5 4.5-3.5"/></svg>',
  'h-treble': '<svg viewBox="0 0 64 64" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><circle cx="32" cy="9" r="3.4"/><path d="M32 12.5V26"/><path d="M32 26c-8 0-13 6-13 12 0 4 2.5 6.5 5.5 6.5"/><path d="M24.5 44.5 20 43l5-2"/><path d="M32 26c8 0 13 6 13 12 0 4-2.5 6.5-5.5 6.5"/><path d="M39.5 44.5 44 43l-5-2"/><path d="M32 26v18c0 4 1.5 6 3.5 6"/></svg>',
};

class LineIcon extends StatelessWidget {
  const LineIcon(this.name, {super.key, this.size = 22, this.color});

  final String name;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? IconTheme.of(context).color ?? Colors.black;
    return SvgPicture.string(
      _icons[name]!,
      width: size,
      height: size,
      theme: SvgTheme(currentColor: c),
    );
  }
}
