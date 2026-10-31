import 'package:hijri/hijri_calendar.dart';

/// Hijri date of [date]. [offsetDays] shifts the computed (Umm al-Qura)
/// calendar: Morocco follows moon sighting and is often one day behind.
(int day, int month, int year) hijriDate(DateTime date, {int offsetDays = 0}) {
  final h = HijriCalendar.fromDate(date.add(Duration(days: offsetDays)));
  return (h.hDay, h.hMonth, h.hYear);
}

const hijriMonths = {
  'ar': ['محرم', 'صفر', 'ربيع الأول', 'ربيع الآخر', 'جمادى الأولى', 'جمادى الآخرة',
      'رجب', 'شعبان', 'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة'],
  'fr': ['Mouharram', 'Safar', 'Rabia al-awal', 'Rabia ath-thani', 'Joumada al-oula',
      'Joumada ath-thania', 'Rajab', 'Chaabane', 'Ramadan', 'Chawwal', 'Dhou al-qi\'da',
      'Dhou al-hijja'],
  'en': ['Muharram', 'Safar', 'Rabi al-Awwal', 'Rabi al-Thani', 'Jumada al-Ula',
      'Jumada al-Akhirah', 'Rajab', 'Shaban', 'Ramadan', 'Shawwal', 'Dhu al-Qadah',
      'Dhu al-Hijjah'],
};

String formatHijri(DateTime date, String lang, {int offsetDays = 0}) {
  final (d, m, y) = hijriDate(date, offsetDays: offsetDays);
  final names = hijriMonths[lang] ?? hijriMonths['fr']!;
  return lang == 'ar' ? '$d ${names[m - 1]} $y هـ' : '$d ${names[m - 1]} $y H';
}
