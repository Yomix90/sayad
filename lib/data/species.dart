import '../widgets/common.dart';

class Species {
  const Species({
    required this.id,
    required this.name,
    required this.latin,
    required this.months,
    required this.habitat,
    required this.bait,
    required this.technique,
    this.minSizeCm,
  });

  final String id;
  final L3 name;
  final String latin;

  /// Best months (1–12).
  final List<int> months;
  final L3 habitat;
  final L3 bait;
  final L3 technique;

  /// Indicative minimum catch size. Check local rules before keeping a fish.
  final int? minSizeCm;
}

const species = [
  Species(
    id: 'bass',
    name: L3('القاروص (ذئب البحر)', 'Loup / Bar', 'European sea bass'),
    latin: 'Dicentrarchus labrax',
    months: [10, 11, 12, 1, 2, 3, 4],
    habitat: L3('الشواطئ الصخرية، مصبات الأنهار، المياه المتحركة.',
        'Côtes rocheuses, estuaires, eaux agitées (écume).',
        'Rocky shores, estuaries, rough foamy water.'),
    bait: L3('الدود، القمرون، السردين، الطعوم الاصطناعية.',
        'Vers, crevettes, sardine, leurres souples et poissons nageurs.',
        'Worms, shrimp, sardine, soft plastics and minnows.'),
    technique: L3('الرمي بالطعم الاصطناعي عند الفجر والغروب، أو الصيد بالقاع.',
        'Pêche aux leurres à l\'aube et au crépuscule, ou surfcasting.',
        'Lure fishing at dawn and dusk, or surfcasting.'),
    minSizeCm: 36,
  ),
  Species(
    id: 'seabream',
    name: L3('الدنيس', 'Dorade royale', 'Gilthead seabream'),
    latin: 'Sparus aurata',
    months: [5, 6, 7, 8, 9, 10],
    habitat: L3('القيعان الرملية والصخرية، الموانئ والمصبات.',
        'Fonds sableux et rocheux, ports, estuaires.',
        'Sandy and rocky bottoms, harbours, estuaries.'),
    bait: L3('بلح البحر، القمرون، السلطعون، الدود.',
        'Moules, crevettes, crabes, vers.',
        'Mussels, shrimp, crab, worms.'),
    technique: L3('الصيد بالقاع بخيط رفيع وصنارة قوية.',
        'Pêche à soutenir ou surfcasting, hameçon solide.',
        'Bottom fishing with a strong hook.'),
    minSizeCm: 23,
  ),
  Species(
    id: 'sar',
    name: L3('الشرغو (الصار)', 'Sar commun', 'White seabream'),
    latin: 'Diplodus sargus',
    months: [9, 10, 11, 12, 1, 2, 3],
    habitat: L3('الصخور والحواجز، المياه المضطربة.',
        'Rochers, digues, eaux remuées.',
        'Rocks, breakwaters, rough water.'),
    bait: L3('بلح البحر، الدود، القمرون، الخبز.',
        'Moules, vers, crevettes, pain.',
        'Mussels, worms, shrimp, bread.'),
    technique: L3('الصيد بالعوامة أو بالقاع قرب الصخور.',
        'Pêche au flotteur ou au posé près des roches.',
        'Float fishing or ledgering near rocks.'),
    minSizeCm: 23,
  ),
  Species(
    id: 'meagre',
    name: L3('الكوربين', 'Courbine (maigre)', 'Meagre'),
    latin: 'Argyrosomus regius',
    months: [4, 5, 6, 7, 8, 9],
    habitat: L3('المصبات والشواطئ الرملية، المياه العكرة.',
        'Estuaires, plages de sable, eaux troubles.',
        'Estuaries, sandy beaches, murky water.'),
    bait: L3('السمك الحي، الحبار، السردين.',
        'Vif, calamar, sardine.',
        'Live bait, squid, sardine.'),
    technique: L3('الصيد الليلي بالقاع بعدة قوية.',
        'Surfcasting de nuit avec matériel puissant.',
        'Night surfcasting with heavy tackle.'),
    minSizeCm: 45,
  ),
  Species(
    id: 'pandora',
    name: L3('الباجو', 'Pageot', 'Common pandora'),
    latin: 'Pagellus erythrinus',
    months: [3, 4, 5, 6, 7, 8, 9, 10],
    habitat: L3('القيعان الرملية والطينية قرب الصخور.',
        'Fonds sablo-vaseux près des roches.',
        'Sandy-muddy bottoms near rocks.'),
    bait: L3('الدود، الحبار، القمرون.', 'Vers, calamar, crevettes.',
        'Worms, squid, shrimp.'),
    technique: L3('الصيد من القارب بالقاع.', 'Pêche en bateau à soutenir.',
        'Bottom fishing from a boat.'),
    minSizeCm: 15,
  ),
  Species(
    id: 'grouper',
    name: L3('الميرو (الهامور)', 'Mérou', 'Dusky grouper'),
    latin: 'Epinephelus marginatus',
    months: [6, 7, 8, 9],
    habitat: L3('الصخور العميقة والكهوف.', 'Roches profondes, grottes.',
        'Deep rocks and caves.'),
    bait: L3('الأخطبوط، الحبار، السمك الحي.', 'Poulpe, calamar, vif.',
        'Octopus, squid, live bait.'),
    technique: L3('الصيد العمودي من القارب بعدة قوية. نوع محمي في عدة مناطق.',
        'Pêche verticale en bateau, matériel puissant. Espèce protégée dans plusieurs zones.',
        'Vertical fishing from a boat, heavy tackle. Protected in many areas.'),
    minSizeCm: 45,
  ),
  Species(
    id: 'sole',
    name: L3('سمك موسى', 'Sole', 'Common sole'),
    latin: 'Solea solea',
    months: [11, 12, 1, 2, 3],
    habitat: L3('القيعان الرملية والطينية.', 'Fonds sableux et vaseux.',
        'Sandy and muddy bottoms.'),
    bait: L3('الدود.', 'Vers (arénicole, néréis).', 'Worms (lugworm, ragworm).'),
    technique: L3('الصيد الليلي بالقاع بصنارة صغيرة.',
        'Surfcasting de nuit, petit hameçon.',
        'Night surfcasting with small hooks.'),
    minSizeCm: 24,
  ),
  Species(
    id: 'mackerel',
    name: L3('الإسقمري (الكوالة)', 'Maquereau', 'Atlantic mackerel'),
    latin: 'Scomber scombrus',
    months: [4, 5, 6, 7, 8, 9],
    habitat: L3('أسراب في المياه المفتوحة وقرب الموانئ.',
        'Bancs en pleine eau et près des ports.',
        'Schools in open water and near harbours.'),
    bait: L3('الريش (السابيكي)، قطع السمك، الملعقة المعدنية.',
        'Plumes (mitraillette), lanières de poisson, cuillers.',
        'Feathers (sabiki), fish strips, spoons.'),
    technique: L3('الرمي والسحب السريع.', 'Lancer-ramener rapide.',
        'Fast cast and retrieve.'),
    minSizeCm: 20,
  ),
  Species(
    id: 'squid',
    name: L3('الكلمار (الحبار)', 'Calamar', 'European squid'),
    latin: 'Loligo vulgaris',
    months: [10, 11, 12, 1, 2],
    habitat: L3('الموانئ المضاءة ليلاً والقيعان الرملية.',
        'Ports éclairés la nuit, fonds sableux.',
        'Lit harbours at night, sandy bottoms.'),
    bait: L3('طعوم الحبار الاصطناعية (الجيغ).', 'Turluttes (egi).',
        'Squid jigs (egi).'),
    technique: L3('الإيغينغ ليلاً قرب الأضواء.', 'Eging de nuit près des lumières.',
        'Eging at night near lights.'),
  ),
  Species(
    id: 'bluefish',
    name: L3('الدفيلة (الشرّان)', 'Tassergal', 'Bluefish'),
    latin: 'Pomatomus saltatrix',
    months: [6, 7, 8, 9, 10, 11],
    habitat: L3('الشواطئ والمصبات، يطارد أسراب السمك الصغير.',
        'Plages et estuaires, chasse les bancs de petits poissons.',
        'Beaches and estuaries, chasing baitfish.'),
    bait: L3('السردين، الطعوم المعدنية، السمك الحي.',
        'Sardine, leurres métalliques, vif.',
        'Sardine, metal lures, live bait.'),
    technique: L3('الرمي بالطعم المعدني مع سلك فولاذي (أسنان حادة).',
        'Leurres métalliques avec bas de ligne acier (dents coupantes).',
        'Metal lures with a wire leader (sharp teeth).'),
    minSizeCm: 30,
  ),
];

Species? speciesById(String id) {
  for (final s in species) {
    if (s.id == id) return s;
  }
  return null;
}
