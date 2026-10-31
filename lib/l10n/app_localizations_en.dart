// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Sayad';

  @override
  String get tabToday => 'Today';

  @override
  String get tabMap => 'Map';

  @override
  String get tabPrayer => 'Prayer';

  @override
  String get tabSettings => 'Settings';

  @override
  String get loading => 'Loading…';

  @override
  String get retry => 'Retry';

  @override
  String get errorLoad => 'Could not load data. Check your connection.';

  @override
  String get locationDenied =>
      'Location denied: using default position (Casablanca).';

  @override
  String get fishingIndex => 'Fishing index';

  @override
  String get fishingPoor => 'Poor';

  @override
  String get fishingFair => 'Fair';

  @override
  String get fishingGood => 'Good';

  @override
  String get fishingExcellent => 'Excellent';

  @override
  String get weather => 'Weather';

  @override
  String get sea => 'Sea';

  @override
  String get wind => 'Wind';

  @override
  String get gusts => 'Gusts';

  @override
  String get pressure => 'Pressure';

  @override
  String get temperature => 'Temperature';

  @override
  String get waves => 'Waves';

  @override
  String get wavePeriod => 'Period';

  @override
  String get waterTemp => 'Water';

  @override
  String get tides => 'Tides';

  @override
  String get highTide => 'High tide';

  @override
  String get lowTide => 'Low tide';

  @override
  String get noMarineData => 'No marine data for this point (inland area).';

  @override
  String get sunMoon => 'Sun and moon';

  @override
  String get sunrise => 'Sunrise';

  @override
  String get sunset => 'Sunset';

  @override
  String get moonPhase => 'Moon phase';

  @override
  String get illumination => 'Illumination';

  @override
  String get moonNew => 'New moon';

  @override
  String get moonWaxingCrescent => 'Waxing crescent';

  @override
  String get moonFirstQuarter => 'First quarter';

  @override
  String get moonWaxingGibbous => 'Waxing gibbous';

  @override
  String get moonFull => 'Full moon';

  @override
  String get moonWaningGibbous => 'Waning gibbous';

  @override
  String get moonLastQuarter => 'Last quarter';

  @override
  String get moonWaningCrescent => 'Waning crescent';

  @override
  String get next24h => 'Next 24 h';

  @override
  String get mySpots => 'My spots';

  @override
  String get addSpotHint => 'Long-press the map to add a spot';

  @override
  String get addSpot => 'Add a spot';

  @override
  String get spotName => 'Spot name';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get forecastHere => 'Forecast here';

  @override
  String get myPosition => 'My position';

  @override
  String get prayerTimes => 'Prayer times';

  @override
  String get fajr => 'Fajr';

  @override
  String get sunrisePrayer => 'Sunrise';

  @override
  String get dhuhr => 'Dhuhr';

  @override
  String get asr => 'Asr';

  @override
  String get maghrib => 'Maghrib';

  @override
  String get isha => 'Isha';

  @override
  String get qibla => 'Qibla direction';

  @override
  String qiblaDegrees(String deg) {
    return '$deg° from north';
  }

  @override
  String get language => 'Language';

  @override
  String get systemLanguage => 'System language';

  @override
  String get about => 'About';

  @override
  String get dataSources =>
      'Data: Open-Meteo (weather and sea), OpenStreetMap and OpenSeaMap (maps). Tides are modelled: do not use them for navigation.';

  @override
  String get kmh => 'km/h';

  @override
  String get hpa => 'hPa';

  @override
  String get meters => 'm';

  @override
  String get seconds => 's';

  @override
  String get tabForecast => 'Forecast';

  @override
  String get tabTools => 'Tools';

  @override
  String get hour => 'Hour';

  @override
  String get humidity => 'Humidity';

  @override
  String get current => 'Current';

  @override
  String get tidalRange => 'Tidal range';

  @override
  String get tidesDisclaimer =>
      'Tides come from a global model and may differ near the coast. Do not use for navigation.';

  @override
  String get solunarCalendar => 'Solunar calendar';

  @override
  String get solunarHelp =>
      'Major periods: moon overhead or underfoot (2 h). Minor periods: moonrise and moonset (1 h). Times are approximate.';

  @override
  String get major => 'Major';

  @override
  String get minor => 'Minor';

  @override
  String get compass => 'Compass';

  @override
  String get noCompassSensor => 'Your phone has no compass sensor.';

  @override
  String get compassHelp =>
      'Hold the phone flat, away from metal. To calibrate, move it in a figure 8.';

  @override
  String get knots => 'Fishing knots';

  @override
  String get species => 'Species';

  @override
  String get inSeason => 'in season';

  @override
  String get sizeDisclaimer =>
      'Minimum sizes are indicative. Check local rules before keeping a fish.';

  @override
  String get bestSeason => 'Best months';

  @override
  String get habitat => 'Habitat';

  @override
  String get bait => 'Bait';

  @override
  String get technique => 'Technique';

  @override
  String get minSize => 'Minimum size';

  @override
  String get catchLog => 'Catch log';

  @override
  String get addCatch => 'Add a catch';

  @override
  String get noCatches =>
      'No catches yet. Log your catches to find your best conditions.';

  @override
  String get statistics => 'Statistics';

  @override
  String get totalCatches => 'Catches';

  @override
  String get biggestCatch => 'Heaviest';

  @override
  String get topSpecies => 'Top species';

  @override
  String get otherSpecies => 'Other species…';

  @override
  String get speciesName => 'Species name';

  @override
  String get weightKg => 'Weight (kg)';

  @override
  String get lengthCm => 'Length (cm)';

  @override
  String get note => 'Note (bait, technique…)';

  @override
  String get catchAutoInfo =>
      'Date, position, wind, waves and moon phase are saved automatically.';

  @override
  String get placesNearby => 'Nearby shops and ports';

  @override
  String get placesError => 'Could not load places. Try again later.';

  @override
  String get fishingShop => 'Fishing shop';

  @override
  String get port => 'Harbour';

  @override
  String get marina => 'Marina';

  @override
  String get slipway => 'Slipway';

  @override
  String get seeAll => 'See all';

  @override
  String placesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count places found',
      one: '1 place found',
      zero: 'No places found here',
    );
    return '$_temp0';
  }

  @override
  String get subtitle => 'Angler\'s guide';

  @override
  String get changeTheme => 'Switch theme';

  @override
  String get morocco => 'Morocco';

  @override
  String get gpsOn => 'GPS on';

  @override
  String get gpsOff => 'GPS off';

  @override
  String get condPoor => 'Poor conditions';

  @override
  String get condFair => 'Fair conditions';

  @override
  String get condGood => 'Good conditions';

  @override
  String get condExcellent => 'Excellent conditions';

  @override
  String majorNow(String end) {
    return 'Major period now, until $end.';
  }

  @override
  String nextMajor(String range) {
    return 'Next major period: $range.';
  }

  @override
  String get indexNote =>
      'Activity depends on the moon, pressure, wind and sea.';

  @override
  String pressureRising(String v) {
    return 'Rising (+$v)';
  }

  @override
  String pressureFalling(String v) {
    return 'Falling (−$v)';
  }

  @override
  String get pressureSteady => 'Steady';

  @override
  String get solunarTable => 'Solunar table';

  @override
  String get h24 => '24 h';

  @override
  String get majorPeriod => 'Major period';

  @override
  String get minorPeriod => 'Minor period';

  @override
  String get swell => 'Swell';

  @override
  String get noMarineShort => 'No marine data';

  @override
  String get surfaceTemp => 'Surface temperature';

  @override
  String get airTemp => 'Air';

  @override
  String get wxClear => 'Clear';

  @override
  String get wxCloudy => 'Cloudy';

  @override
  String get wxFog => 'Fog';

  @override
  String get wxRain => 'Rain';

  @override
  String get wxSnow => 'Snow';

  @override
  String get wxStorm => 'Storm';

  @override
  String get sun => 'Sun';

  @override
  String get moon => 'Moon';

  @override
  String get rise => 'Rise';

  @override
  String get set => 'Set';

  @override
  String get days7 => '7 days';

  @override
  String get hwShort => 'HW';

  @override
  String get lwShort => 'LW';

  @override
  String get nextTide => 'Next tide';

  @override
  String inDuration(String d) {
    return 'in $d';
  }

  @override
  String get upcoming => 'Next';

  @override
  String get marineForecast => 'Marine forecast';

  @override
  String bestWindow(String range, String state) {
    return 'Best window: $range · $state sea';
  }

  @override
  String get temperatureShort => 'Temp.';

  @override
  String get calm => 'Calm';

  @override
  String get moderate => 'Moderate';

  @override
  String get rough => 'Rough';

  @override
  String spotsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count spots',
      one: '1 spot',
      zero: 'No spots',
    );
    return '$_temp0';
  }

  @override
  String get selectedPoint => 'Selected point';

  @override
  String get pointKind => 'Map point';

  @override
  String get mySpot => 'My spot';

  @override
  String get all => 'All';

  @override
  String get placesFilter => 'Shops & ports';

  @override
  String get saved => 'Saved';

  @override
  String get direct => 'Direct';

  @override
  String get coords => 'Position';

  @override
  String get navigate => 'Navigate';

  @override
  String get spotSaved => 'Spot saved ✓';

  @override
  String get guide => 'Guide';

  @override
  String get knotsAndHooks => 'Knots & hooks';

  @override
  String get knotsShort => 'Knots';

  @override
  String get hooks => 'Hooks';

  @override
  String get use => 'Use';

  @override
  String get difficulty => 'Difficulty';

  @override
  String get easy => 'Easy';

  @override
  String get medium => 'Medium';

  @override
  String get steps => 'Steps';

  @override
  String get tip => 'Angler\'s tip';

  @override
  String get speciesSub => 'Seasons, baits and techniques';

  @override
  String get solunarSub => '30 days of periods';

  @override
  String get catchLogSub => 'Your catches and conditions';

  @override
  String get compassSub => 'Heading and qibla';

  @override
  String get prayerSub => 'For your position';

  @override
  String get settingsSub => 'Language, theme, region';

  @override
  String stepOf(int a, int b) {
    return 'Step $a / $b';
  }

  @override
  String get later => 'Later';

  @override
  String get continueLabel => 'Continue';

  @override
  String get start => 'Get started';

  @override
  String get chooseLanguage => 'Choose your language';

  @override
  String get chooseLanguageSub =>
      'The interface and guide are fully translated.';

  @override
  String get chooseRegion => 'Your fishing area';

  @override
  String get chooseRegionSub => 'Used for forecasts and tides when GPS is off.';

  @override
  String get useGps => 'Use my GPS position';

  @override
  String get useGpsSub => 'Most accurate, especially at sea';

  @override
  String get chooseStyle => 'Choose a style';

  @override
  String get chooseStyleSub => 'Change it anytime with the button at the top.';

  @override
  String get styleModern => 'Modern';

  @override
  String get styleModernSub => 'Ocean blue, clean and readable';

  @override
  String get styleClassic => 'Classic';

  @override
  String get styleClassicSub => 'Old nautical chart on parchment';

  @override
  String get appearance => 'Appearance';

  @override
  String get fishingRegion => 'Fishing area';

  @override
  String get replayWelcome => 'Replay the welcome screen';

  @override
  String get loadingTides => 'Reading the tides…';

  @override
  String get loadingMoon => 'Working out the moon…';

  @override
  String get loadingSpots => 'Getting your spots ready…';

  @override
  String get tideSourcePrecise => 'Accurate predictions (WorldTides)';

  @override
  String get tideSourceModel => 'Approximate model (may be 1–2 h off)';

  @override
  String get tidesDisclaimerPrecise =>
      'Heights above chart datum (lowest astronomical tide), as in tide tables. For navigation, always use official documents.';

  @override
  String get tideSourceStormglass => 'Accurate predictions (Stormglass)';

  @override
  String tideSourceCorrected(String port) {
    return 'Accurate: corrected to the $port port tide table';
  }

  @override
  String get tideSourceUncalibrated =>
      'Stormglass not calibrated here (may be up to 1 h off)';

  @override
  String get chooseCity => 'Choose a coastal town';

  @override
  String get searchCity => 'Search a town…';

  @override
  String get noCityFound => 'No town found.';

  @override
  String get changeCity => 'Tap to change town';

  @override
  String get coastMediterranean => 'Mediterranean';

  @override
  String get coastAtlanticNorth => 'North Atlantic';

  @override
  String get coastAtlanticCentre => 'Central Atlantic';

  @override
  String get coastSouss => 'Souss';

  @override
  String get coastSahara => 'Sahara';

  @override
  String get targetDistance => 'Distance to the spot';

  @override
  String get targetBearing => 'Bearing';

  @override
  String get targetSpot => 'Target';

  @override
  String get waitingGps => 'Waiting for GPS…';

  @override
  String get targetHelp =>
      'Follow the arrow. Works without internet or a map, with GPS and compass only.';

  @override
  String get targetNoCompass =>
      'No compass: hold the phone with its top pointing north.';

  @override
  String get guideOffline => 'Guide me (offline)';

  @override
  String get springTide => 'Spring tide';

  @override
  String get neapTide => 'Neap tide';

  @override
  String get midTide => 'Medium tide';

  @override
  String get hijriCalendar => 'Hijri calendar';

  @override
  String get hijriHelp =>
      'Morocco follows the crescent sighting, often a day after the calculation. Pick the right date.';

  @override
  String get hijriMorocco => 'Morocco (default)';

  @override
  String get hijriUmmAlQura => 'Calculated (Umm al-Qura)';

  @override
  String get weatherMap => 'Weather map';

  @override
  String get weatherMapSub => 'Animated wind, waves, rain';

  @override
  String get tips => 'Tips';

  @override
  String get tipsSub => 'Fishing times, tides, safety';

  @override
  String get communitySpots => 'Fishing spots';

  @override
  String get communitySpot => 'Fishing spot';

  @override
  String get shareSpot => 'Share with everyone';

  @override
  String get shareSpotSub => 'Shown after review';

  @override
  String get spotShared => 'Sent, waiting for review ✓';

  @override
  String get spotShareFailed => 'Could not send, try again later';
}
