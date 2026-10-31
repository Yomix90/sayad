import '../widgets/common.dart';

class Tip {
  const Tip(this.title, this.points);
  final L3 title;
  final List<L3> points;
}

const tips = [
  Tip(
    L3('أفضل أوقات الصيد', 'Les meilleurs moments pour pêcher', 'Best times to fish'),
    [
      L3('الفجر والغروب: الضوء الخافت يشجع الأسماك على الاقتراب من الشاطئ للتغذي.',
          'L\'aube et le crépuscule : la lumière faible pousse les poissons à venir se nourrir près du bord.',
          'Dawn and dusk: low light brings fish close to shore to feed.'),
      L3('تغيّر التيار: الساعة التي تسبق المد العالي والساعة التي تليه غالباً ما تكون الأفضل.',
          'La renverse : l\'heure avant et l\'heure après la pleine mer sont souvent les plus actives.',
          'The turn of the tide: the hour before and after high tide is often the most active.'),
      L3('الفترات الكبرى في التقويم الشمسي القمري، خاصة إذا تزامنت مع الفجر أو الغروب.',
          'Les périodes majeures du calendrier solunaire, surtout si elles tombent à l\'aube ou au crépuscule.',
          'Major solunar periods, especially when they fall at dawn or dusk.'),
      L3('الضغط الجوي المنخفض ببطء قبل تغيّر الطقس ينشّط الأسماك؛ الارتفاع المفاجئ يقلل نشاطها.',
          'Une pression qui baisse doucement avant un changement de temps active le poisson ; une hausse brutale le calme.',
          'Slowly falling pressure before a weather change makes fish active; a sharp rise slows them down.'),
      L3('بحر متحرك قليلاً مع رغوة قرب الصخور مثالي للقاروص؛ البحر الهادئ جداً والصافي أصعب.',
          'Une mer un peu agitée avec de l\'écume près des rochers est idéale pour le bar ; une mer très calme et claire est plus difficile.',
          'A slightly rough sea with foam near rocks is ideal for bass; very calm, clear water is harder.'),
    ],
  ),
  Tip(
    L3('المد العالي والجزر: الحمل والكساد', 'Vives-eaux et mortes-eaux (حمل / كساد)', 'Spring and neap tides'),
    [
      L3('الحمل (الماريا الكبيرة): يحدث قرب البدر والمحاق، حين تتّحد جاذبية القمر والشمس. المد أعلى والجزر أدنى والتيارات أقوى.',
          'Vives-eaux (حمل, grande marée) : autour de la pleine et de la nouvelle lune, quand la Lune et le Soleil tirent ensemble. Mers plus hautes, basses mers plus basses, courants plus forts.',
          'Spring tides: around full and new moon, when the Moon and Sun pull together. Higher highs, lower lows, stronger currents.'),
      L3('الكساد (الماريا الصغيرة): قرب التربيعين، الفرق بين المد والجزر صغير والتيارات ضعيفة.',
          'Mortes-eaux (كساد) : aux premiers et derniers quartiers, l\'écart entre haute et basse mer est faible et les courants sont doux.',
          'Neap tides: at the quarter moons, the range is small and currents are gentle.'),
      L3('أكبر الحمل يكون حين يكون القمر قريباً من الأرض، وقرب الاعتدالين في مارس وسبتمبر.',
          'Les plus grandes marées arrivent quand la Lune est au plus près de la Terre, et autour des équinoxes de mars et septembre.',
          'The biggest tides come when the Moon is closest to Earth, and around the March and September equinoxes.'),
      L3('الجزر الكبير وقت مناسب لجمع الطعوم (الدود، بلح البحر، السلطعون) واكتشاف أماكن جديدة.',
          'Les grandes basses mers sont idéales pour ramasser les appâts (vers, moules, crabes) et repérer de nouveaux postes.',
          'Big low tides are ideal for gathering bait (worms, mussels, crabs) and scouting new spots.'),
      L3('في صفحة المد والجزر يظهر نوع كل يوم حسب فارق ارتفاع الماء.',
          'Dans l\'écran Marées, chaque jour est marqué vives-eaux ou mortes-eaux selon son marnage.',
          'The Tides screen marks each day as spring or neap from its tidal range.'),
    ],
  ),
  Tip(
    L3('السلامة في البحر', 'Sécurité en mer et sur les rochers', 'Safety at sea and on rocks'),
    [
      L3('تحقق من الأمواج والرياح قبل الخروج، وتجنب الصخور حين يكون البحر هائجاً.',
          'Vérifiez houle et vent avant de partir ; évitez les rochers quand la mer est agitée.',
          'Check swell and wind before leaving; avoid rocks when the sea is rough.'),
      L3('لا تُدِر ظهرك للبحر أبداً: موجة أكبر قد تأتي فجأة.',
          'Ne tournez jamais le dos à la mer : une vague plus grosse peut arriver sans prévenir.',
          'Never turn your back on the sea: a bigger wave can come without warning.'),
      L3('احذر المد الصاعد الذي قد يقطع طريق العودة.',
          'Attention à la marée montante qui peut couper le chemin du retour.',
          'Watch the rising tide that can cut off your way back.'),
      L3('أخبر أحداً بمكانك ووقت رجوعك، واحمل هاتفاً مشحوناً وسترة نجاة.',
          'Prévenez quelqu\'un de votre spot et de l\'heure de retour ; emportez un téléphone chargé et un gilet.',
          'Tell someone where you go and when you will be back; carry a charged phone and a life jacket.'),
    ],
  ),
];
