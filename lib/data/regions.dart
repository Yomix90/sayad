import 'package:latlong2/latlong.dart' show LatLng;

import '../widgets/common.dart';

/// Stretches of the Moroccan coast, from the Algerian border to Dakhla.
enum Coast { mediterranean, atlanticNorth, atlanticCentre, souss, sahara }

/// A coastal town or fishing spot, used when GPS is off.
class Region {
  const Region(this.id, this.name, this.position, this.coast);
  final String id;
  final L3 name;
  final LatLng position;
  final Coast coast;
}

/// North-east to south-west along the coast. Ids of the first version are
/// kept so saved choices still work.
const regions = [
  // Méditerranée
  Region('saidia', L3('السعيدية', 'Saïdia', 'Saidia'), LatLng(35.0900, -2.2200), Coast.mediterranean),
  Region('capeau', L3('رأس الماء', "Cap de l'Eau (Ras Kebdana)", 'Ras Kebdana'), LatLng(35.1400, -2.4180), Coast.mediterranean),
  Region('nador', L3('الناظور', 'Nador', 'Nador'), LatLng(35.1740, -2.9287), Coast.mediterranean),
  Region('hoceima', L3('الحسيمة', 'Al Hoceïma', 'Al Hoceima'), LatLng(35.2517, -3.9372), Coast.mediterranean),
  Region('calairis', L3('كالا إيريس', 'Cala Iris', 'Cala Iris'), LatLng(35.1480, -4.3660), Coast.mediterranean),
  Region('jebha', L3('الجبهة', 'El Jebha', 'El Jebha'), LatLng(35.2080, -4.6670), Coast.mediterranean),
  Region('ouedlaou', L3('واد لاو', 'Oued Laou', 'Oued Laou'), LatLng(35.4480, -5.0930), Coast.mediterranean),
  Region('martil', L3('مرتيل', 'Martil', 'Martil'), LatLng(35.6170, -5.2750), Coast.mediterranean),
  Region('mdiq', L3('المضيق', "M'diq", "M'diq"), LatLng(35.6850, -5.3250), Coast.mediterranean),
  Region('fnideq', L3('الفنيدق', 'Fnideq', 'Fnideq'), LatLng(35.8490, -5.3570), Coast.mediterranean),
  Region('ksarsghir', L3('القصر الصغير', 'Ksar Sghir', 'Ksar Sghir'), LatLng(35.8450, -5.5570), Coast.mediterranean),
  // Atlantique nord
  Region('tanger', L3('طنجة', 'Tanger', 'Tangier'), LatLng(35.7595, -5.8340), Coast.atlanticNorth),
  Region('asilah', L3('أصيلة', 'Asilah', 'Asilah'), LatLng(35.4650, -6.0340), Coast.atlanticNorth),
  Region('larache', L3('العرائش', 'Larache', 'Larache'), LatLng(35.1932, -6.1557), Coast.atlanticNorth),
  Region('bousselham', L3('مولاي بوسلهام', 'Moulay Bousselham', 'Moulay Bousselham'), LatLng(34.8780, -6.2900), Coast.atlanticNorth),
  Region('mehdia', L3('المهدية', 'Mehdia', 'Mehdia'), LatLng(34.2580, -6.6730), Coast.atlanticNorth),
  Region('rabat', L3('الرباط', 'Rabat', 'Rabat'), LatLng(34.0209, -6.8416), Coast.atlanticNorth),
  Region('temara', L3('شاطئ تمارة', 'Témara Plage', 'Temara Beach'), LatLng(33.9300, -6.9200), Coast.atlanticNorth),
  Region('skhirat', L3('الصخيرات', 'Skhirat', 'Skhirat'), LatLng(33.8530, -7.0350), Coast.atlanticNorth),
  Region('bouznika', L3('بوزنيقة', 'Bouznika', 'Bouznika'), LatLng(33.7890, -7.1600), Coast.atlanticNorth),
  Region('mohammedia', L3('المحمدية', 'Mohammedia', 'Mohammedia'), LatLng(33.6866, -7.3830), Coast.atlanticNorth),
  Region('casablanca', L3('الدار البيضاء', 'Casablanca', 'Casablanca'), LatLng(33.5731, -7.5898), Coast.atlanticNorth),
  Region('darbouazza', L3('دار بوعزة', 'Dar Bouazza', 'Dar Bouazza'), LatLng(33.5200, -7.8200), Coast.atlanticNorth),
  // Atlantique centre
  Region('azemmour', L3('أزمور', 'Azemmour', 'Azemmour'), LatLng(33.2870, -8.3430), Coast.atlanticCentre),
  Region('eljadida', L3('الجديدة', 'El Jadida', 'El Jadida'), LatLng(33.2549, -8.5079), Coast.atlanticCentre),
  Region('sidibouzid', L3('سيدي بوزيد', 'Sidi Bouzid', 'Sidi Bouzid'), LatLng(33.2300, -8.5550), Coast.atlanticCentre),
  Region('oualidia', L3('الوليدية', 'Oualidia', 'Oualidia'), LatLng(32.7330, -9.0330), Coast.atlanticCentre),
  Region('safi', L3('آسفي', 'Safi', 'Safi'), LatLng(32.2994, -9.2372), Coast.atlanticCentre),
  Region('souiria', L3('الصويرية القديمة', 'Souiria Lakdima', 'Souiria Lakdima'), LatLng(32.0480, -9.3420), Coast.atlanticCentre),
  Region('essaouira', L3('الصويرة', 'Essaouira', 'Essaouira'), LatLng(31.5085, -9.7595), Coast.atlanticCentre),
  Region('sidikaouki', L3('سيدي كاوكي', 'Sidi Kaouki', 'Sidi Kaouki'), LatLng(31.3550, -9.7950), Coast.atlanticCentre),
  // Souss
  Region('imsouane', L3('إمسوان', 'Imsouane', 'Imsouane'), LatLng(30.8400, -9.8230), Coast.souss),
  Region('taghazout', L3('تغازوت', 'Taghazout', 'Taghazout'), LatLng(30.5450, -9.7090), Coast.souss),
  Region('agadir', L3('أكادير', 'Agadir', 'Agadir'), LatLng(30.4202, -9.5982), Coast.souss),
  Region('tifnit', L3('تيفنيت', 'Tifnit – Sidi Bibi', 'Tifnit – Sidi Bibi'), LatLng(30.1950, -9.6400), Coast.souss),
  Region('mirleft', L3('ميرلفت', 'Mirleft', 'Mirleft'), LatLng(29.5830, -10.0400), Coast.souss),
  Region('sidiifni', L3('سيدي إفني', 'Sidi Ifni', 'Sidi Ifni'), LatLng(29.3797, -10.1729), Coast.souss),
  // Sahara
  Region('tantan', L3('طانطان الشاطئ', 'Tan-Tan Plage', 'Tan-Tan Beach'), LatLng(28.4900, -11.3300), Coast.sahara),
  Region('akhfennir', L3('أخفنير', 'Akhfennir', 'Akhfennir'), LatLng(28.0930, -12.0470), Coast.sahara),
  Region('tarfaya', L3('طرفاية', 'Tarfaya', 'Tarfaya'), LatLng(27.9390, -12.9260), Coast.sahara),
  Region('laayoune', L3('العيون الشاطئ', 'Laâyoune Plage', 'Laayoune Beach'), LatLng(27.1500, -13.2000), Coast.sahara),
  Region('boujdour', L3('بوجدور', 'Boujdour', 'Boujdour'), LatLng(26.1270, -14.4840), Coast.sahara),
  Region('dakhla', L3('الداخلة', 'Dakhla', 'Dakhla'), LatLng(23.6848, -15.9580), Coast.sahara),
];

Region regionById(String? id) =>
    regions.firstWhere((r) => r.id == id, orElse: () => regions.firstWhere((r) => r.id == 'casablanca'));
