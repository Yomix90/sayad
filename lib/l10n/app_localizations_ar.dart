// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'الصياد';

  @override
  String get tabToday => 'اليوم';

  @override
  String get tabMap => 'الخريطة';

  @override
  String get tabPrayer => 'الصلاة';

  @override
  String get tabSettings => 'الإعدادات';

  @override
  String get loading => 'جارٍ التحميل…';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get errorLoad => 'تعذّر تحميل البيانات. تحقّق من الاتصال.';

  @override
  String get locationDenied =>
      'تم رفض تحديد الموقع: يُستعمل الموقع الافتراضي (الدار البيضاء).';

  @override
  String get fishingIndex => 'مؤشر الصيد';

  @override
  String get fishingPoor => 'ضعيف';

  @override
  String get fishingFair => 'متوسط';

  @override
  String get fishingGood => 'جيد';

  @override
  String get fishingExcellent => 'ممتاز';

  @override
  String get weather => 'الطقس';

  @override
  String get sea => 'البحر';

  @override
  String get wind => 'الرياح';

  @override
  String get gusts => 'الهبّات';

  @override
  String get pressure => 'الضغط';

  @override
  String get temperature => 'الحرارة';

  @override
  String get waves => 'الأمواج';

  @override
  String get wavePeriod => 'الدورة';

  @override
  String get waterTemp => 'الماء';

  @override
  String get tides => 'المد والجزر';

  @override
  String get highTide => 'المد العالي';

  @override
  String get lowTide => 'الجزر';

  @override
  String get noMarineData => 'لا توجد بيانات بحرية لهذه النقطة (منطقة برية).';

  @override
  String get sunMoon => 'الشمس والقمر';

  @override
  String get sunrise => 'شروق الشمس';

  @override
  String get sunset => 'غروب الشمس';

  @override
  String get moonPhase => 'طور القمر';

  @override
  String get illumination => 'الإضاءة';

  @override
  String get moonNew => 'محاق';

  @override
  String get moonWaxingCrescent => 'هلال متزايد';

  @override
  String get moonFirstQuarter => 'تربيع أول';

  @override
  String get moonWaxingGibbous => 'أحدب متزايد';

  @override
  String get moonFull => 'بدر';

  @override
  String get moonWaningGibbous => 'أحدب متناقص';

  @override
  String get moonLastQuarter => 'تربيع أخير';

  @override
  String get moonWaningCrescent => 'هلال متناقص';

  @override
  String get next24h => 'الـ 24 ساعة القادمة';

  @override
  String get mySpots => 'مواقعي';

  @override
  String get addSpotHint => 'اضغط مطولاً على الخريطة لإضافة موقع';

  @override
  String get addSpot => 'إضافة موقع';

  @override
  String get spotName => 'اسم الموقع';

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String get delete => 'حذف';

  @override
  String get forecastHere => 'التوقعات هنا';

  @override
  String get myPosition => 'موقعي';

  @override
  String get prayerTimes => 'أوقات الصلاة';

  @override
  String get fajr => 'الفجر';

  @override
  String get sunrisePrayer => 'الشروق';

  @override
  String get dhuhr => 'الظهر';

  @override
  String get asr => 'العصر';

  @override
  String get maghrib => 'المغرب';

  @override
  String get isha => 'العشاء';

  @override
  String get qibla => 'اتجاه القبلة';

  @override
  String qiblaDegrees(String deg) {
    return '$deg° من الشمال';
  }

  @override
  String get language => 'اللغة';

  @override
  String get systemLanguage => 'لغة النظام';

  @override
  String get about => 'حول التطبيق';

  @override
  String get dataSources =>
      'البيانات: Open-Meteo (الطقس والبحر)، OpenStreetMap و OpenSeaMap (الخرائط). بيانات المد والجزر تقديرية: لا تعتمد عليها في الملاحة.';

  @override
  String get kmh => 'كم/س';

  @override
  String get hpa => 'هكتوباسكال';

  @override
  String get meters => 'م';

  @override
  String get seconds => 'ث';

  @override
  String get tabForecast => 'التوقعات';

  @override
  String get tabTools => 'الأدوات';

  @override
  String get hour => 'الساعة';

  @override
  String get humidity => 'الرطوبة';

  @override
  String get current => 'التيار';

  @override
  String get tidalRange => 'فارق المد والجزر';

  @override
  String get tidesDisclaimer =>
      'المد والجزر محسوب من نموذج عالمي وقد يختلف عن الواقع قرب السواحل. لا تعتمد عليه في الملاحة.';

  @override
  String get solunarCalendar => 'التقويم الشمسي القمري';

  @override
  String get solunarHelp =>
      'الفترات الكبرى: مرور القمر فوق الرأس أو تحت القدمين (ساعتان). الفترات الصغرى: شروق القمر وغروبه (ساعة). الأوقات تقريبية.';

  @override
  String get major => 'كبرى';

  @override
  String get minor => 'صغرى';

  @override
  String get compass => 'البوصلة';

  @override
  String get noCompassSensor => 'لا يتوفر هاتفك على مستشعر البوصلة.';

  @override
  String get compassHelp =>
      'ضع الهاتف أفقياً وبعيداً عن المعادن. لمعايرة البوصلة حرّك الهاتف على شكل 8.';

  @override
  String get knots => 'عقد الصيد';

  @override
  String get species => 'الأسماك';

  @override
  String get inSeason => 'موسمه الآن';

  @override
  String get sizeDisclaimer =>
      'الأحجام الدنيا إرشادية فقط. تحقّق من القوانين المحلية قبل الاحتفاظ بأي سمكة.';

  @override
  String get bestSeason => 'أفضل الأشهر';

  @override
  String get habitat => 'المكان';

  @override
  String get bait => 'الطعم';

  @override
  String get technique => 'التقنية';

  @override
  String get minSize => 'الحجم الأدنى';

  @override
  String get catchLog => 'سجل الصيد';

  @override
  String get addCatch => 'إضافة صيد';

  @override
  String get noCatches =>
      'لا توجد أي صيدة بعد. سجّل صيدك لمعرفة أفضل الظروف لك.';

  @override
  String get statistics => 'الإحصائيات';

  @override
  String get totalCatches => 'عدد الصيدات';

  @override
  String get biggestCatch => 'الأثقل';

  @override
  String get topSpecies => 'الأكثر صيداً';

  @override
  String get otherSpecies => 'نوع آخر…';

  @override
  String get speciesName => 'اسم النوع';

  @override
  String get weightKg => 'الوزن (كغ)';

  @override
  String get lengthCm => 'الطول (سم)';

  @override
  String get note => 'ملاحظة (طعم، تقنية…)';

  @override
  String get catchAutoInfo =>
      'يتم حفظ التاريخ والموقع والرياح والأمواج وطور القمر تلقائياً.';

  @override
  String get placesNearby => 'محلات وموانئ قريبة';

  @override
  String get placesError => 'تعذّر تحميل الأماكن. حاول لاحقاً.';

  @override
  String get fishingShop => 'محل لوازم الصيد';

  @override
  String get port => 'ميناء';

  @override
  String get marina => 'مرسى';

  @override
  String get slipway => 'منحدر إنزال القوارب';

  @override
  String get seeAll => 'عرض الكل';

  @override
  String placesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مكان',
      zero: 'لم يتم العثور على أي مكان هنا',
    );
    return '$_temp0';
  }

  @override
  String get subtitle => 'دليل الصياد';

  @override
  String get changeTheme => 'تغيير المظهر';

  @override
  String get morocco => 'المغرب';

  @override
  String get gpsOn => 'GPS مفعّل';

  @override
  String get gpsOff => 'GPS متوقف';

  @override
  String get condPoor => 'ظروف ضعيفة';

  @override
  String get condFair => 'ظروف متوسطة';

  @override
  String get condGood => 'ظروف جيدة';

  @override
  String get condExcellent => 'ظروف ممتازة';

  @override
  String majorNow(String end) {
    return 'فترة كبرى جارية حتى $end.';
  }

  @override
  String nextMajor(String range) {
    return 'الفترة الكبرى القادمة: $range.';
  }

  @override
  String get indexNote => 'النشاط يتأثر بالقمر والضغط والرياح والبحر.';

  @override
  String pressureRising(String v) {
    return 'في ارتفاع (+$v)';
  }

  @override
  String pressureFalling(String v) {
    return 'في انخفاض (−$v)';
  }

  @override
  String get pressureSteady => 'مستقر';

  @override
  String get solunarTable => 'الجدول الشمسي القمري';

  @override
  String get h24 => '24 س';

  @override
  String get majorPeriod => 'فترة كبرى';

  @override
  String get minorPeriod => 'فترة صغرى';

  @override
  String get swell => 'الأمواج';

  @override
  String get noMarineShort => 'لا بيانات بحرية';

  @override
  String get surfaceTemp => 'حرارة السطح';

  @override
  String get airTemp => 'الهواء';

  @override
  String get wxClear => 'صافٍ';

  @override
  String get wxCloudy => 'غائم';

  @override
  String get wxFog => 'ضباب';

  @override
  String get wxRain => 'مطر';

  @override
  String get wxSnow => 'ثلج';

  @override
  String get wxStorm => 'عاصفة';

  @override
  String get sun => 'الشمس';

  @override
  String get moon => 'القمر';

  @override
  String get rise => 'الشروق';

  @override
  String get set => 'الغروب';

  @override
  String get days7 => '7 أيام';

  @override
  String get hwShort => 'مدّ';

  @override
  String get lwShort => 'جزر';

  @override
  String get nextTide => 'المدّ القادم';

  @override
  String inDuration(String d) {
    return 'بعد $d';
  }

  @override
  String get upcoming => 'القادم';

  @override
  String get marineForecast => 'التوقعات البحرية';

  @override
  String bestWindow(String range, String state) {
    return 'أفضل فترة: $range · بحر $state';
  }

  @override
  String get temperatureShort => 'الحرارة';

  @override
  String get calm => 'هادئ';

  @override
  String get moderate => 'معتدل';

  @override
  String get rough => 'هائج';

  @override
  String spotsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مواقع',
      one: 'موقع واحد',
      zero: 'لا مواقع',
    );
    return '$_temp0';
  }

  @override
  String get selectedPoint => 'النقطة المختارة';

  @override
  String get pointKind => 'نقطة على الخريطة';

  @override
  String get mySpot => 'موقعي';

  @override
  String get all => 'الكل';

  @override
  String get placesFilter => 'المتاجر والموانئ';

  @override
  String get saved => 'محفوظ';

  @override
  String get direct => 'مباشرة';

  @override
  String get coords => 'الموقع';

  @override
  String get navigate => 'ابدأ الملاحة';

  @override
  String get spotSaved => 'تم حفظ الموقع ✓';

  @override
  String get guide => 'الدليل';

  @override
  String get knotsAndHooks => 'العقد والخطاطيف';

  @override
  String get knotsShort => 'العقد';

  @override
  String get hooks => 'الخطاطيف';

  @override
  String get use => 'الاستعمال';

  @override
  String get difficulty => 'الصعوبة';

  @override
  String get easy => 'سهل';

  @override
  String get medium => 'متوسط';

  @override
  String get steps => 'الخطوات';

  @override
  String get tip => 'نصيحة الصياد';

  @override
  String get speciesSub => 'المواسم والطعوم والتقنيات';

  @override
  String get solunarSub => '30 يوماً من الفترات';

  @override
  String get catchLogSub => 'صيدك وظروفه';

  @override
  String get compassSub => 'الاتجاه والقبلة';

  @override
  String get prayerSub => 'حسب موقعك';

  @override
  String get settingsSub => 'اللغة والمظهر والمنطقة';

  @override
  String stepOf(int a, int b) {
    return 'الخطوة $a / $b';
  }

  @override
  String get later => 'لاحقاً';

  @override
  String get continueLabel => 'متابعة';

  @override
  String get start => 'ابدأ';

  @override
  String get chooseLanguage => 'اختر لغتك';

  @override
  String get chooseLanguageSub => 'الواجهة والدليل مترجمان بالكامل.';

  @override
  String get chooseRegion => 'منطقة الصيد الخاصة بك';

  @override
  String get chooseRegionSub =>
      'تُستعمل للتوقعات والمد والجزر عندما يكون GPS متوقفاً.';

  @override
  String get useGps => 'استعمال موقعي (GPS)';

  @override
  String get useGpsSub => 'الأدق، خاصة في البحر';

  @override
  String get chooseStyle => 'اختر المظهر';

  @override
  String get chooseStyleSub => 'يمكنك تغييره في أي وقت من الزر أعلى الشاشة.';

  @override
  String get styleModern => 'عصري';

  @override
  String get styleModernSub => 'أزرق المحيط، واضح ومريح';

  @override
  String get styleClassic => 'قديم';

  @override
  String get styleClassicSub => 'خريطة بحرية قديمة على الرق';

  @override
  String get appearance => 'المظهر';

  @override
  String get fishingRegion => 'منطقة الصيد';

  @override
  String get replayWelcome => 'إعادة شاشة الترحيب';

  @override
  String get loadingTides => 'قراءة المد والجزر…';

  @override
  String get loadingMoon => 'حساب أطوار القمر…';

  @override
  String get loadingSpots => 'تجهيز مواقع الصيد…';

  @override
  String get tideSourcePrecise => 'توقعات دقيقة (WorldTides)';

  @override
  String get tideSourceModel => 'نموذج تقريبي (قد يختلف بساعة أو ساعتين)';

  @override
  String get tidesDisclaimerPrecise =>
      'الارتفاعات فوق الصفر البحري (أدنى جزر فلكي)، مثل جداول المد والجزر. للملاحة استعمل دائماً الوثائق الرسمية.';

  @override
  String get tideSourceStormglass => 'توقعات دقيقة (Stormglass)';

  @override
  String tideSourceCorrected(String port) {
    return 'دقيق: مصحَّح حسب جدول ميناء $port';
  }

  @override
  String get tideSourceUncalibrated =>
      'Stormglass غير مُعايَر هنا (فرق محتمل حتى ساعة)';

  @override
  String get chooseCity => 'اختر مدينة ساحلية';

  @override
  String get searchCity => 'ابحث عن مدينة…';

  @override
  String get noCityFound => 'لا توجد مدينة بهذا الاسم.';

  @override
  String get changeCity => 'اضغط لتغيير المدينة';

  @override
  String get coastMediterranean => 'البحر الأبيض المتوسط';

  @override
  String get coastAtlanticNorth => 'الأطلسي الشمالي';

  @override
  String get coastAtlanticCentre => 'الأطلسي الأوسط';

  @override
  String get coastSouss => 'سوس';

  @override
  String get coastSahara => 'الصحراء';

  @override
  String get targetDistance => 'المسافة إلى الهدف';

  @override
  String get targetBearing => 'الاتجاه';

  @override
  String get targetSpot => 'الهدف';

  @override
  String get waitingGps => 'في انتظار إشارة GPS…';

  @override
  String get targetHelp =>
      'اتبع السهم. يعمل بدون إنترنت وبدون خريطة، فقط بـ GPS والبوصلة.';

  @override
  String get targetNoCompass => 'لا توجد بوصلة: أمسك الهاتف وأعلاه نحو الشمال.';

  @override
  String get guideOffline => 'توجيه بدون إنترنت';

  @override
  String get springTide => 'حمل (ماريا كبيرة)';

  @override
  String get neapTide => 'كساد (ماريا صغيرة)';

  @override
  String get midTide => 'مد متوسط';

  @override
  String get hijriCalendar => 'التقويم الهجري';

  @override
  String get hijriHelp =>
      'المغرب يعتمد رؤية الهلال، وغالباً ما يتأخر يوماً عن الحساب الفلكي. اختر التاريخ الصحيح.';

  @override
  String get hijriMorocco => 'المغرب (افتراضي)';

  @override
  String get hijriUmmAlQura => 'الحساب (أم القرى)';

  @override
  String get weatherMap => 'خريطة الطقس';

  @override
  String get weatherMapSub => 'رياح، أمواج، أمطار متحركة';

  @override
  String get tips => 'نصائح';

  @override
  String get tipsSub => 'أوقات الصيد، المد، السلامة';

  @override
  String get communitySpots => 'مواقع الصيد';

  @override
  String get communitySpot => 'موقع صيد';

  @override
  String get shareSpot => 'مشاركة مع الجميع';

  @override
  String get shareSpotSub => 'يظهر بعد موافقة الإدارة';

  @override
  String get spotShared => 'تم الإرسال، في انتظار الموافقة ✓';

  @override
  String get spotShareFailed => 'تعذّر الإرسال، حاول لاحقاً';

  @override
  String get bigTides => 'أكبر المد والجزر في السنة';

  @override
  String get bigTidesSub => 'أفضل أيام جمع الطعوم';

  @override
  String get bigTidesHelp =>
      'أيام الحمل (بعد المحاق والبدر بيوم ونصف). الأكبر مميَّزة: الجزر فيها أدنى، وهي الأفضل لجمع الطعوم والصيد عند الحواف.';

  @override
  String get bigTideTop => 'من الأكبر هذه السنة';

  @override
  String get coefficientShort => 'معامل';

  @override
  String get coefficientDisclaimer =>
      'المعامل محسوب من مواقع القمر والشمس (≈). الترتيب بين الأيام موثوق، أما القيمة فتقريبية.';

  @override
  String get sky => 'الشمس والقمر في السماء';

  @override
  String get skySub => 'الاتجاه والارتفاع طوال اليوم';

  @override
  String get skyNow => 'الآن';

  @override
  String get skyHelp =>
      'الدائرة الخارجية هي الأفق، والمركز فوق رأسك. الأصفر: مسار الشمس، الرمادي: مسار القمر.';

  @override
  String get skyHeight => 'الارتفاع';

  @override
  String get skyDirection => 'الاتجاه';

  @override
  String get skyDistance => 'المسافة';

  @override
  String get perigee => 'القمر قريب من الأرض: مد وجزر أقوى';

  @override
  String get proposeShop => 'اقتراح محل هنا';

  @override
  String get shopName => 'اسم المحل';

  @override
  String get phone => 'الهاتف';

  @override
  String get city => 'المدينة';

  @override
  String get send => 'إرسال';

  @override
  String get contactUs => 'تواصل معنا';
}
