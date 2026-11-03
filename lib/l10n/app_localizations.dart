import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In fr, this message translates to:
  /// **'Sayad'**
  String get appTitle;

  /// No description provided for @tabToday.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get tabToday;

  /// No description provided for @tabMap.
  ///
  /// In fr, this message translates to:
  /// **'Carte'**
  String get tabMap;

  /// No description provided for @tabPrayer.
  ///
  /// In fr, this message translates to:
  /// **'Prière'**
  String get tabPrayer;

  /// No description provided for @tabSettings.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get tabSettings;

  /// No description provided for @loading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement…'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// No description provided for @errorLoad.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les données. Vérifiez votre connexion.'**
  String get errorLoad;

  /// No description provided for @locationDenied.
  ///
  /// In fr, this message translates to:
  /// **'Localisation refusée : position par défaut utilisée (Casablanca).'**
  String get locationDenied;

  /// No description provided for @fishingIndex.
  ///
  /// In fr, this message translates to:
  /// **'Indice de pêche'**
  String get fishingIndex;

  /// No description provided for @fishingPoor.
  ///
  /// In fr, this message translates to:
  /// **'Faible'**
  String get fishingPoor;

  /// No description provided for @fishingFair.
  ///
  /// In fr, this message translates to:
  /// **'Moyen'**
  String get fishingFair;

  /// No description provided for @fishingGood.
  ///
  /// In fr, this message translates to:
  /// **'Bon'**
  String get fishingGood;

  /// No description provided for @fishingExcellent.
  ///
  /// In fr, this message translates to:
  /// **'Excellent'**
  String get fishingExcellent;

  /// No description provided for @weather.
  ///
  /// In fr, this message translates to:
  /// **'Météo'**
  String get weather;

  /// No description provided for @sea.
  ///
  /// In fr, this message translates to:
  /// **'Mer'**
  String get sea;

  /// No description provided for @wind.
  ///
  /// In fr, this message translates to:
  /// **'Vent'**
  String get wind;

  /// No description provided for @gusts.
  ///
  /// In fr, this message translates to:
  /// **'Rafales'**
  String get gusts;

  /// No description provided for @pressure.
  ///
  /// In fr, this message translates to:
  /// **'Pression'**
  String get pressure;

  /// No description provided for @temperature.
  ///
  /// In fr, this message translates to:
  /// **'Température'**
  String get temperature;

  /// No description provided for @waves.
  ///
  /// In fr, this message translates to:
  /// **'Vagues'**
  String get waves;

  /// No description provided for @wavePeriod.
  ///
  /// In fr, this message translates to:
  /// **'Période'**
  String get wavePeriod;

  /// No description provided for @waterTemp.
  ///
  /// In fr, this message translates to:
  /// **'Eau'**
  String get waterTemp;

  /// No description provided for @tides.
  ///
  /// In fr, this message translates to:
  /// **'Marées'**
  String get tides;

  /// No description provided for @highTide.
  ///
  /// In fr, this message translates to:
  /// **'Pleine mer'**
  String get highTide;

  /// No description provided for @lowTide.
  ///
  /// In fr, this message translates to:
  /// **'Basse mer'**
  String get lowTide;

  /// No description provided for @noMarineData.
  ///
  /// In fr, this message translates to:
  /// **'Pas de données marines pour ce point (zone terrestre).'**
  String get noMarineData;

  /// No description provided for @sunMoon.
  ///
  /// In fr, this message translates to:
  /// **'Soleil et lune'**
  String get sunMoon;

  /// No description provided for @sunrise.
  ///
  /// In fr, this message translates to:
  /// **'Lever du soleil'**
  String get sunrise;

  /// No description provided for @sunset.
  ///
  /// In fr, this message translates to:
  /// **'Coucher du soleil'**
  String get sunset;

  /// No description provided for @moonPhase.
  ///
  /// In fr, this message translates to:
  /// **'Phase de lune'**
  String get moonPhase;

  /// No description provided for @illumination.
  ///
  /// In fr, this message translates to:
  /// **'Illumination'**
  String get illumination;

  /// No description provided for @moonNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle lune'**
  String get moonNew;

  /// No description provided for @moonWaxingCrescent.
  ///
  /// In fr, this message translates to:
  /// **'Premier croissant'**
  String get moonWaxingCrescent;

  /// No description provided for @moonFirstQuarter.
  ///
  /// In fr, this message translates to:
  /// **'Premier quartier'**
  String get moonFirstQuarter;

  /// No description provided for @moonWaxingGibbous.
  ///
  /// In fr, this message translates to:
  /// **'Gibbeuse croissante'**
  String get moonWaxingGibbous;

  /// No description provided for @moonFull.
  ///
  /// In fr, this message translates to:
  /// **'Pleine lune'**
  String get moonFull;

  /// No description provided for @moonWaningGibbous.
  ///
  /// In fr, this message translates to:
  /// **'Gibbeuse décroissante'**
  String get moonWaningGibbous;

  /// No description provided for @moonLastQuarter.
  ///
  /// In fr, this message translates to:
  /// **'Dernier quartier'**
  String get moonLastQuarter;

  /// No description provided for @moonWaningCrescent.
  ///
  /// In fr, this message translates to:
  /// **'Dernier croissant'**
  String get moonWaningCrescent;

  /// No description provided for @next24h.
  ///
  /// In fr, this message translates to:
  /// **'Prochaines 24 h'**
  String get next24h;

  /// No description provided for @mySpots.
  ///
  /// In fr, this message translates to:
  /// **'Mes spots'**
  String get mySpots;

  /// No description provided for @addSpotHint.
  ///
  /// In fr, this message translates to:
  /// **'Appui long sur la carte pour ajouter un spot'**
  String get addSpotHint;

  /// No description provided for @addSpot.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un spot'**
  String get addSpot;

  /// No description provided for @spotName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du spot'**
  String get spotName;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete;

  /// No description provided for @forecastHere.
  ///
  /// In fr, this message translates to:
  /// **'Prévisions ici'**
  String get forecastHere;

  /// No description provided for @myPosition.
  ///
  /// In fr, this message translates to:
  /// **'Ma position'**
  String get myPosition;

  /// No description provided for @prayerTimes.
  ///
  /// In fr, this message translates to:
  /// **'Heures de prière'**
  String get prayerTimes;

  /// No description provided for @fajr.
  ///
  /// In fr, this message translates to:
  /// **'Fajr'**
  String get fajr;

  /// No description provided for @sunrisePrayer.
  ///
  /// In fr, this message translates to:
  /// **'Chourouq'**
  String get sunrisePrayer;

  /// No description provided for @dhuhr.
  ///
  /// In fr, this message translates to:
  /// **'Dhohr'**
  String get dhuhr;

  /// No description provided for @asr.
  ///
  /// In fr, this message translates to:
  /// **'Asr'**
  String get asr;

  /// No description provided for @maghrib.
  ///
  /// In fr, this message translates to:
  /// **'Maghrib'**
  String get maghrib;

  /// No description provided for @isha.
  ///
  /// In fr, this message translates to:
  /// **'Icha'**
  String get isha;

  /// No description provided for @qibla.
  ///
  /// In fr, this message translates to:
  /// **'Direction de la qibla'**
  String get qibla;

  /// No description provided for @qiblaDegrees.
  ///
  /// In fr, this message translates to:
  /// **'{deg}° depuis le nord'**
  String qiblaDegrees(String deg);

  /// No description provided for @language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;

  /// No description provided for @systemLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Langue du système'**
  String get systemLanguage;

  /// No description provided for @about.
  ///
  /// In fr, this message translates to:
  /// **'À propos'**
  String get about;

  /// No description provided for @dataSources.
  ///
  /// In fr, this message translates to:
  /// **'Données : Open-Meteo (météo et mer), OpenStreetMap et OpenSeaMap (cartes). Les marées sont un modèle : ne les utilisez pas pour la navigation.'**
  String get dataSources;

  /// No description provided for @kmh.
  ///
  /// In fr, this message translates to:
  /// **'km/h'**
  String get kmh;

  /// No description provided for @hpa.
  ///
  /// In fr, this message translates to:
  /// **'hPa'**
  String get hpa;

  /// No description provided for @meters.
  ///
  /// In fr, this message translates to:
  /// **'m'**
  String get meters;

  /// No description provided for @seconds.
  ///
  /// In fr, this message translates to:
  /// **'s'**
  String get seconds;

  /// No description provided for @tabForecast.
  ///
  /// In fr, this message translates to:
  /// **'Prévisions'**
  String get tabForecast;

  /// No description provided for @tabTools.
  ///
  /// In fr, this message translates to:
  /// **'Outils'**
  String get tabTools;

  /// No description provided for @hour.
  ///
  /// In fr, this message translates to:
  /// **'Heure'**
  String get hour;

  /// No description provided for @humidity.
  ///
  /// In fr, this message translates to:
  /// **'Humidité'**
  String get humidity;

  /// No description provided for @current.
  ///
  /// In fr, this message translates to:
  /// **'Courant'**
  String get current;

  /// No description provided for @tidalRange.
  ///
  /// In fr, this message translates to:
  /// **'Marnage'**
  String get tidalRange;

  /// No description provided for @tidesDisclaimer.
  ///
  /// In fr, this message translates to:
  /// **'Les marées viennent d\'un modèle mondial et peuvent différer de la réalité près des côtes. Ne pas utiliser pour la navigation.'**
  String get tidesDisclaimer;

  /// No description provided for @solunarCalendar.
  ///
  /// In fr, this message translates to:
  /// **'Calendrier solunaire'**
  String get solunarCalendar;

  /// No description provided for @solunarHelp.
  ///
  /// In fr, this message translates to:
  /// **'Périodes majeures : lune au zénith ou au nadir (2 h). Périodes mineures : lever et coucher de la lune (1 h). Horaires approximatifs.'**
  String get solunarHelp;

  /// No description provided for @major.
  ///
  /// In fr, this message translates to:
  /// **'Majeure'**
  String get major;

  /// No description provided for @minor.
  ///
  /// In fr, this message translates to:
  /// **'Mineure'**
  String get minor;

  /// No description provided for @compass.
  ///
  /// In fr, this message translates to:
  /// **'Boussole'**
  String get compass;

  /// No description provided for @noCompassSensor.
  ///
  /// In fr, this message translates to:
  /// **'Votre téléphone n\'a pas de capteur de boussole.'**
  String get noCompassSensor;

  /// No description provided for @compassHelp.
  ///
  /// In fr, this message translates to:
  /// **'Tenez le téléphone à plat, loin du métal. Pour calibrer, faites un 8 avec le téléphone.'**
  String get compassHelp;

  /// No description provided for @knots.
  ///
  /// In fr, this message translates to:
  /// **'Nœuds de pêche'**
  String get knots;

  /// No description provided for @species.
  ///
  /// In fr, this message translates to:
  /// **'Espèces'**
  String get species;

  /// No description provided for @inSeason.
  ///
  /// In fr, this message translates to:
  /// **'en saison'**
  String get inSeason;

  /// No description provided for @sizeDisclaimer.
  ///
  /// In fr, this message translates to:
  /// **'Les tailles minimales sont indicatives. Vérifiez la réglementation locale avant de garder un poisson.'**
  String get sizeDisclaimer;

  /// No description provided for @bestSeason.
  ///
  /// In fr, this message translates to:
  /// **'Meilleurs mois'**
  String get bestSeason;

  /// No description provided for @habitat.
  ///
  /// In fr, this message translates to:
  /// **'Habitat'**
  String get habitat;

  /// No description provided for @bait.
  ///
  /// In fr, this message translates to:
  /// **'Appâts'**
  String get bait;

  /// No description provided for @technique.
  ///
  /// In fr, this message translates to:
  /// **'Technique'**
  String get technique;

  /// No description provided for @minSize.
  ///
  /// In fr, this message translates to:
  /// **'Taille minimale'**
  String get minSize;

  /// No description provided for @catchLog.
  ///
  /// In fr, this message translates to:
  /// **'Journal de pêche'**
  String get catchLog;

  /// No description provided for @addCatch.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une prise'**
  String get addCatch;

  /// No description provided for @noCatches.
  ///
  /// In fr, this message translates to:
  /// **'Aucune prise pour l\'instant. Enregistrez vos prises pour découvrir vos meilleures conditions.'**
  String get noCatches;

  /// No description provided for @statistics.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques'**
  String get statistics;

  /// No description provided for @totalCatches.
  ///
  /// In fr, this message translates to:
  /// **'Prises'**
  String get totalCatches;

  /// No description provided for @biggestCatch.
  ///
  /// In fr, this message translates to:
  /// **'La plus lourde'**
  String get biggestCatch;

  /// No description provided for @topSpecies.
  ///
  /// In fr, this message translates to:
  /// **'Espèce n°1'**
  String get topSpecies;

  /// No description provided for @otherSpecies.
  ///
  /// In fr, this message translates to:
  /// **'Autre espèce…'**
  String get otherSpecies;

  /// No description provided for @speciesName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de l\'espèce'**
  String get speciesName;

  /// No description provided for @weightKg.
  ///
  /// In fr, this message translates to:
  /// **'Poids (kg)'**
  String get weightKg;

  /// No description provided for @lengthCm.
  ///
  /// In fr, this message translates to:
  /// **'Taille (cm)'**
  String get lengthCm;

  /// No description provided for @note.
  ///
  /// In fr, this message translates to:
  /// **'Note (appât, technique…)'**
  String get note;

  /// No description provided for @catchAutoInfo.
  ///
  /// In fr, this message translates to:
  /// **'La date, la position, le vent, les vagues et la phase de lune sont enregistrés automatiquement.'**
  String get catchAutoInfo;

  /// No description provided for @placesNearby.
  ///
  /// In fr, this message translates to:
  /// **'Magasins et ports proches'**
  String get placesNearby;

  /// No description provided for @placesError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les lieux. Réessayez plus tard.'**
  String get placesError;

  /// No description provided for @fishingShop.
  ///
  /// In fr, this message translates to:
  /// **'Magasin de pêche'**
  String get fishingShop;

  /// No description provided for @port.
  ///
  /// In fr, this message translates to:
  /// **'Port'**
  String get port;

  /// No description provided for @marina.
  ///
  /// In fr, this message translates to:
  /// **'Marina'**
  String get marina;

  /// No description provided for @slipway.
  ///
  /// In fr, this message translates to:
  /// **'Cale de mise à l\'eau'**
  String get slipway;

  /// No description provided for @seeAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout voir'**
  String get seeAll;

  /// No description provided for @placesFound.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun lieu trouvé ici} =1{1 lieu trouvé} other{{count} lieux trouvés}}'**
  String placesFound(int count);

  /// No description provided for @subtitle.
  ///
  /// In fr, this message translates to:
  /// **'Guide du pêcheur'**
  String get subtitle;

  /// No description provided for @changeTheme.
  ///
  /// In fr, this message translates to:
  /// **'Changer de thème'**
  String get changeTheme;

  /// No description provided for @morocco.
  ///
  /// In fr, this message translates to:
  /// **'Maroc'**
  String get morocco;

  /// No description provided for @gpsOn.
  ///
  /// In fr, this message translates to:
  /// **'GPS actif'**
  String get gpsOn;

  /// No description provided for @gpsOff.
  ///
  /// In fr, this message translates to:
  /// **'GPS coupé'**
  String get gpsOff;

  /// No description provided for @condPoor.
  ///
  /// In fr, this message translates to:
  /// **'Conditions faibles'**
  String get condPoor;

  /// No description provided for @condFair.
  ///
  /// In fr, this message translates to:
  /// **'Conditions moyennes'**
  String get condFair;

  /// No description provided for @condGood.
  ///
  /// In fr, this message translates to:
  /// **'Bonnes conditions'**
  String get condGood;

  /// No description provided for @condExcellent.
  ///
  /// In fr, this message translates to:
  /// **'Excellentes conditions'**
  String get condExcellent;

  /// No description provided for @majorNow.
  ///
  /// In fr, this message translates to:
  /// **'Période majeure en cours jusqu\'à {end}.'**
  String majorNow(String end);

  /// No description provided for @nextMajor.
  ///
  /// In fr, this message translates to:
  /// **'Prochaine période majeure : {range}.'**
  String nextMajor(String range);

  /// No description provided for @indexNote.
  ///
  /// In fr, this message translates to:
  /// **'L\'activité dépend de la lune, de la pression, du vent et de la mer.'**
  String get indexNote;

  /// No description provided for @pressureRising.
  ///
  /// In fr, this message translates to:
  /// **'En hausse (+{v})'**
  String pressureRising(String v);

  /// No description provided for @pressureFalling.
  ///
  /// In fr, this message translates to:
  /// **'En baisse (−{v})'**
  String pressureFalling(String v);

  /// No description provided for @pressureSteady.
  ///
  /// In fr, this message translates to:
  /// **'Stable'**
  String get pressureSteady;

  /// No description provided for @solunarTable.
  ///
  /// In fr, this message translates to:
  /// **'Table solunaire'**
  String get solunarTable;

  /// No description provided for @h24.
  ///
  /// In fr, this message translates to:
  /// **'24 h'**
  String get h24;

  /// No description provided for @majorPeriod.
  ///
  /// In fr, this message translates to:
  /// **'Période majeure'**
  String get majorPeriod;

  /// No description provided for @minorPeriod.
  ///
  /// In fr, this message translates to:
  /// **'Période mineure'**
  String get minorPeriod;

  /// No description provided for @swell.
  ///
  /// In fr, this message translates to:
  /// **'Houle'**
  String get swell;

  /// No description provided for @noMarineShort.
  ///
  /// In fr, this message translates to:
  /// **'Pas de données marines'**
  String get noMarineShort;

  /// No description provided for @surfaceTemp.
  ///
  /// In fr, this message translates to:
  /// **'Température de surface'**
  String get surfaceTemp;

  /// No description provided for @airTemp.
  ///
  /// In fr, this message translates to:
  /// **'Air'**
  String get airTemp;

  /// No description provided for @wxClear.
  ///
  /// In fr, this message translates to:
  /// **'Dégagé'**
  String get wxClear;

  /// No description provided for @wxCloudy.
  ///
  /// In fr, this message translates to:
  /// **'Nuageux'**
  String get wxCloudy;

  /// No description provided for @wxFog.
  ///
  /// In fr, this message translates to:
  /// **'Brouillard'**
  String get wxFog;

  /// No description provided for @wxRain.
  ///
  /// In fr, this message translates to:
  /// **'Pluie'**
  String get wxRain;

  /// No description provided for @wxSnow.
  ///
  /// In fr, this message translates to:
  /// **'Neige'**
  String get wxSnow;

  /// No description provided for @wxStorm.
  ///
  /// In fr, this message translates to:
  /// **'Orage'**
  String get wxStorm;

  /// No description provided for @sun.
  ///
  /// In fr, this message translates to:
  /// **'Soleil'**
  String get sun;

  /// No description provided for @moon.
  ///
  /// In fr, this message translates to:
  /// **'Lune'**
  String get moon;

  /// No description provided for @rise.
  ///
  /// In fr, this message translates to:
  /// **'Lever'**
  String get rise;

  /// No description provided for @set.
  ///
  /// In fr, this message translates to:
  /// **'Coucher'**
  String get set;

  /// No description provided for @days7.
  ///
  /// In fr, this message translates to:
  /// **'7 jours'**
  String get days7;

  /// No description provided for @hwShort.
  ///
  /// In fr, this message translates to:
  /// **'PM'**
  String get hwShort;

  /// No description provided for @lwShort.
  ///
  /// In fr, this message translates to:
  /// **'BM'**
  String get lwShort;

  /// No description provided for @nextTide.
  ///
  /// In fr, this message translates to:
  /// **'Prochaine marée'**
  String get nextTide;

  /// No description provided for @inDuration.
  ///
  /// In fr, this message translates to:
  /// **'dans {d}'**
  String inDuration(String d);

  /// No description provided for @upcoming.
  ///
  /// In fr, this message translates to:
  /// **'À venir'**
  String get upcoming;

  /// No description provided for @marineForecast.
  ///
  /// In fr, this message translates to:
  /// **'Prévisions marines'**
  String get marineForecast;

  /// No description provided for @bestWindow.
  ///
  /// In fr, this message translates to:
  /// **'Meilleur créneau : {range} · mer {state}'**
  String bestWindow(String range, String state);

  /// No description provided for @temperatureShort.
  ///
  /// In fr, this message translates to:
  /// **'Temp.'**
  String get temperatureShort;

  /// No description provided for @calm.
  ///
  /// In fr, this message translates to:
  /// **'Calme'**
  String get calm;

  /// No description provided for @moderate.
  ///
  /// In fr, this message translates to:
  /// **'Modérée'**
  String get moderate;

  /// No description provided for @rough.
  ///
  /// In fr, this message translates to:
  /// **'Agitée'**
  String get rough;

  /// No description provided for @spotsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun spot} =1{1 spot} other{{count} spots}}'**
  String spotsCount(int count);

  /// No description provided for @selectedPoint.
  ///
  /// In fr, this message translates to:
  /// **'Point sélectionné'**
  String get selectedPoint;

  /// No description provided for @pointKind.
  ///
  /// In fr, this message translates to:
  /// **'Point de la carte'**
  String get pointKind;

  /// No description provided for @mySpot.
  ///
  /// In fr, this message translates to:
  /// **'Mon spot'**
  String get mySpot;

  /// No description provided for @all.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get all;

  /// No description provided for @placesFilter.
  ///
  /// In fr, this message translates to:
  /// **'Magasins & ports'**
  String get placesFilter;

  /// No description provided for @saved.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegardé'**
  String get saved;

  /// No description provided for @direct.
  ///
  /// In fr, this message translates to:
  /// **'Directe'**
  String get direct;

  /// No description provided for @coords.
  ///
  /// In fr, this message translates to:
  /// **'Position'**
  String get coords;

  /// No description provided for @navigate.
  ///
  /// In fr, this message translates to:
  /// **'Naviguer'**
  String get navigate;

  /// No description provided for @spotSaved.
  ///
  /// In fr, this message translates to:
  /// **'Spot sauvegardé ✓'**
  String get spotSaved;

  /// No description provided for @guide.
  ///
  /// In fr, this message translates to:
  /// **'Guide'**
  String get guide;

  /// No description provided for @knotsAndHooks.
  ///
  /// In fr, this message translates to:
  /// **'Nœuds & hameçons'**
  String get knotsAndHooks;

  /// No description provided for @knotsShort.
  ///
  /// In fr, this message translates to:
  /// **'Nœuds'**
  String get knotsShort;

  /// No description provided for @hooks.
  ///
  /// In fr, this message translates to:
  /// **'Hameçons'**
  String get hooks;

  /// No description provided for @use.
  ///
  /// In fr, this message translates to:
  /// **'Usage'**
  String get use;

  /// No description provided for @difficulty.
  ///
  /// In fr, this message translates to:
  /// **'Difficulté'**
  String get difficulty;

  /// No description provided for @easy.
  ///
  /// In fr, this message translates to:
  /// **'Facile'**
  String get easy;

  /// No description provided for @medium.
  ///
  /// In fr, this message translates to:
  /// **'Moyen'**
  String get medium;

  /// No description provided for @steps.
  ///
  /// In fr, this message translates to:
  /// **'Étapes'**
  String get steps;

  /// No description provided for @tip.
  ///
  /// In fr, this message translates to:
  /// **'Conseil du pêcheur'**
  String get tip;

  /// No description provided for @speciesSub.
  ///
  /// In fr, this message translates to:
  /// **'Saisons, appâts et techniques'**
  String get speciesSub;

  /// No description provided for @solunarSub.
  ///
  /// In fr, this message translates to:
  /// **'30 jours de périodes'**
  String get solunarSub;

  /// No description provided for @catchLogSub.
  ///
  /// In fr, this message translates to:
  /// **'Vos prises et leurs conditions'**
  String get catchLogSub;

  /// No description provided for @compassSub.
  ///
  /// In fr, this message translates to:
  /// **'Cap et qibla'**
  String get compassSub;

  /// No description provided for @prayerSub.
  ///
  /// In fr, this message translates to:
  /// **'Selon votre position'**
  String get prayerSub;

  /// No description provided for @settingsSub.
  ///
  /// In fr, this message translates to:
  /// **'Langue, thème, région'**
  String get settingsSub;

  /// No description provided for @stepOf.
  ///
  /// In fr, this message translates to:
  /// **'Étape {a} / {b}'**
  String stepOf(int a, int b);

  /// No description provided for @later.
  ///
  /// In fr, this message translates to:
  /// **'Plus tard'**
  String get later;

  /// No description provided for @continueLabel.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get continueLabel;

  /// No description provided for @start.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get start;

  /// No description provided for @chooseLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez votre langue'**
  String get chooseLanguage;

  /// No description provided for @chooseLanguageSub.
  ///
  /// In fr, this message translates to:
  /// **'L\'interface et le guide sont entièrement traduits.'**
  String get chooseLanguageSub;

  /// No description provided for @chooseRegion.
  ///
  /// In fr, this message translates to:
  /// **'Votre région de pêche'**
  String get chooseRegion;

  /// No description provided for @chooseRegionSub.
  ///
  /// In fr, this message translates to:
  /// **'Elle sert pour les prévisions et les marées quand le GPS est coupé.'**
  String get chooseRegionSub;

  /// No description provided for @useGps.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser ma position GPS'**
  String get useGps;

  /// No description provided for @useGpsSub.
  ///
  /// In fr, this message translates to:
  /// **'Le plus précis, surtout en mer'**
  String get useGpsSub;

  /// No description provided for @chooseStyle.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez le style'**
  String get chooseStyle;

  /// No description provided for @chooseStyleSub.
  ///
  /// In fr, this message translates to:
  /// **'Modifiable à tout moment avec le bouton en haut de l\'écran.'**
  String get chooseStyleSub;

  /// No description provided for @styleModern.
  ///
  /// In fr, this message translates to:
  /// **'Moderne'**
  String get styleModern;

  /// No description provided for @styleModernSub.
  ///
  /// In fr, this message translates to:
  /// **'Bleu océan, clair et lisible'**
  String get styleModernSub;

  /// No description provided for @styleClassic.
  ///
  /// In fr, this message translates to:
  /// **'Ancien'**
  String get styleClassic;

  /// No description provided for @styleClassicSub.
  ///
  /// In fr, this message translates to:
  /// **'Carte marine ancienne sur parchemin'**
  String get styleClassicSub;

  /// No description provided for @appearance.
  ///
  /// In fr, this message translates to:
  /// **'Apparence'**
  String get appearance;

  /// No description provided for @fishingRegion.
  ///
  /// In fr, this message translates to:
  /// **'Région de pêche'**
  String get fishingRegion;

  /// No description provided for @replayWelcome.
  ///
  /// In fr, this message translates to:
  /// **'Revoir l\'écran d\'accueil'**
  String get replayWelcome;

  /// No description provided for @loadingTides.
  ///
  /// In fr, this message translates to:
  /// **'Lecture des marées…'**
  String get loadingTides;

  /// No description provided for @loadingMoon.
  ///
  /// In fr, this message translates to:
  /// **'Calcul de la lune…'**
  String get loadingMoon;

  /// No description provided for @loadingSpots.
  ///
  /// In fr, this message translates to:
  /// **'Préparation des spots…'**
  String get loadingSpots;

  /// No description provided for @tideSourcePrecise.
  ///
  /// In fr, this message translates to:
  /// **'Prévisions précises (WorldTides)'**
  String get tideSourcePrecise;

  /// No description provided for @tideSourceModel.
  ///
  /// In fr, this message translates to:
  /// **'Modèle approximatif (écart possible de 1 à 2 h)'**
  String get tideSourceModel;

  /// No description provided for @tidesDisclaimerPrecise.
  ///
  /// In fr, this message translates to:
  /// **'Hauteurs au-dessus du zéro des cartes (plus basse mer astronomique), comme les annuaires de marée. Pour la navigation, utilisez toujours les documents officiels.'**
  String get tidesDisclaimerPrecise;

  /// No description provided for @tideSourceStormglass.
  ///
  /// In fr, this message translates to:
  /// **'Prévisions précises (Stormglass)'**
  String get tideSourceStormglass;

  /// No description provided for @tideSourceCorrected.
  ///
  /// In fr, this message translates to:
  /// **'Précis : corrigé sur la table du port de {port}'**
  String tideSourceCorrected(String port);

  /// No description provided for @tideSourceUncalibrated.
  ///
  /// In fr, this message translates to:
  /// **'Stormglass non calibré ici (écart possible jusqu\'à 1 h)'**
  String get tideSourceUncalibrated;

  /// No description provided for @chooseCity.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une ville côtière'**
  String get chooseCity;

  /// No description provided for @searchCity.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher une ville…'**
  String get searchCity;

  /// No description provided for @noCityFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucune ville trouvée.'**
  String get noCityFound;

  /// No description provided for @changeCity.
  ///
  /// In fr, this message translates to:
  /// **'Appuyez pour changer de ville'**
  String get changeCity;

  /// No description provided for @coastMediterranean.
  ///
  /// In fr, this message translates to:
  /// **'Méditerranée'**
  String get coastMediterranean;

  /// No description provided for @coastAtlanticNorth.
  ///
  /// In fr, this message translates to:
  /// **'Atlantique nord'**
  String get coastAtlanticNorth;

  /// No description provided for @coastAtlanticCentre.
  ///
  /// In fr, this message translates to:
  /// **'Atlantique centre'**
  String get coastAtlanticCentre;

  /// No description provided for @coastSouss.
  ///
  /// In fr, this message translates to:
  /// **'Souss'**
  String get coastSouss;

  /// No description provided for @coastSahara.
  ///
  /// In fr, this message translates to:
  /// **'Sahara'**
  String get coastSahara;

  /// No description provided for @targetDistance.
  ///
  /// In fr, this message translates to:
  /// **'Distance jusqu\'au spot'**
  String get targetDistance;

  /// No description provided for @targetBearing.
  ///
  /// In fr, this message translates to:
  /// **'Cap'**
  String get targetBearing;

  /// No description provided for @targetSpot.
  ///
  /// In fr, this message translates to:
  /// **'Spot visé'**
  String get targetSpot;

  /// No description provided for @waitingGps.
  ///
  /// In fr, this message translates to:
  /// **'Recherche du signal GPS…'**
  String get waitingGps;

  /// No description provided for @targetHelp.
  ///
  /// In fr, this message translates to:
  /// **'Suivez la flèche. Fonctionne sans internet ni carte, avec le GPS et la boussole seulement.'**
  String get targetHelp;

  /// No description provided for @targetNoCompass.
  ///
  /// In fr, this message translates to:
  /// **'Pas de boussole : tenez le téléphone le haut vers le nord.'**
  String get targetNoCompass;

  /// No description provided for @guideOffline.
  ///
  /// In fr, this message translates to:
  /// **'Guider (hors ligne)'**
  String get guideOffline;

  /// No description provided for @springTide.
  ///
  /// In fr, this message translates to:
  /// **'Vives-eaux (حمل)'**
  String get springTide;

  /// No description provided for @neapTide.
  ///
  /// In fr, this message translates to:
  /// **'Mortes-eaux (كساد)'**
  String get neapTide;

  /// No description provided for @midTide.
  ///
  /// In fr, this message translates to:
  /// **'Marée moyenne'**
  String get midTide;

  /// No description provided for @hijriCalendar.
  ///
  /// In fr, this message translates to:
  /// **'Calendrier hégirien'**
  String get hijriCalendar;

  /// No description provided for @hijriHelp.
  ///
  /// In fr, this message translates to:
  /// **'Le Maroc suit l\'observation du croissant, souvent un jour après le calcul. Choisissez la date correcte.'**
  String get hijriHelp;

  /// No description provided for @hijriMorocco.
  ///
  /// In fr, this message translates to:
  /// **'Maroc (par défaut)'**
  String get hijriMorocco;

  /// No description provided for @hijriUmmAlQura.
  ///
  /// In fr, this message translates to:
  /// **'Calcul (Umm al-Qura)'**
  String get hijriUmmAlQura;

  /// No description provided for @weatherMap.
  ///
  /// In fr, this message translates to:
  /// **'Carte météo'**
  String get weatherMap;

  /// No description provided for @weatherMapSub.
  ///
  /// In fr, this message translates to:
  /// **'Vent, vagues, pluie animés'**
  String get weatherMapSub;

  /// No description provided for @tips.
  ///
  /// In fr, this message translates to:
  /// **'Conseils'**
  String get tips;

  /// No description provided for @tipsSub.
  ///
  /// In fr, this message translates to:
  /// **'Moments de pêche, marées, sécurité'**
  String get tipsSub;

  /// No description provided for @communitySpots.
  ///
  /// In fr, this message translates to:
  /// **'Spots de pêche'**
  String get communitySpots;

  /// No description provided for @communitySpot.
  ///
  /// In fr, this message translates to:
  /// **'Spot de pêche'**
  String get communitySpot;

  /// No description provided for @shareSpot.
  ///
  /// In fr, this message translates to:
  /// **'Partager avec tous'**
  String get shareSpot;

  /// No description provided for @shareSpotSub.
  ///
  /// In fr, this message translates to:
  /// **'Visible après validation'**
  String get shareSpotSub;

  /// No description provided for @spotShared.
  ///
  /// In fr, this message translates to:
  /// **'Envoyé, en attente de validation ✓'**
  String get spotShared;

  /// No description provided for @spotShareFailed.
  ///
  /// In fr, this message translates to:
  /// **'Envoi impossible, réessayez plus tard'**
  String get spotShareFailed;

  /// No description provided for @bigTides.
  ///
  /// In fr, this message translates to:
  /// **'Grandes marées de l\'année'**
  String get bigTides;

  /// No description provided for @bigTidesSub.
  ///
  /// In fr, this message translates to:
  /// **'Meilleurs jours pour les appâts'**
  String get bigTidesSub;

  /// No description provided for @bigTidesHelp.
  ///
  /// In fr, this message translates to:
  /// **'Jours de vives-eaux (1,5 jour après la nouvelle et la pleine lune). Les plus fortes sont mises en avant : la mer y descend le plus bas, idéal pour ramasser les appâts et pêcher les bordures.'**
  String get bigTidesHelp;

  /// No description provided for @bigTideTop.
  ///
  /// In fr, this message translates to:
  /// **'parmi les plus fortes de l\'année'**
  String get bigTideTop;

  /// No description provided for @coefficientShort.
  ///
  /// In fr, this message translates to:
  /// **'coef.'**
  String get coefficientShort;

  /// No description provided for @coefficientDisclaimer.
  ///
  /// In fr, this message translates to:
  /// **'Coefficient calculé à partir des positions de la Lune et du Soleil (≈). Le classement des jours est fiable ; la valeur est approximative.'**
  String get coefficientDisclaimer;

  /// No description provided for @sky.
  ///
  /// In fr, this message translates to:
  /// **'Soleil et lune dans le ciel'**
  String get sky;

  /// No description provided for @skySub.
  ///
  /// In fr, this message translates to:
  /// **'Direction et hauteur toute la journée'**
  String get skySub;

  /// No description provided for @skyNow.
  ///
  /// In fr, this message translates to:
  /// **'Maintenant'**
  String get skyNow;

  /// No description provided for @skyHelp.
  ///
  /// In fr, this message translates to:
  /// **'Le cercle extérieur est l\'horizon, le centre est au-dessus de vous. Jaune : trajet du soleil, gris : trajet de la lune.'**
  String get skyHelp;

  /// No description provided for @skyHeight.
  ///
  /// In fr, this message translates to:
  /// **'Hauteur'**
  String get skyHeight;

  /// No description provided for @skyDirection.
  ///
  /// In fr, this message translates to:
  /// **'Direction'**
  String get skyDirection;

  /// No description provided for @skyDistance.
  ///
  /// In fr, this message translates to:
  /// **'Distance'**
  String get skyDistance;

  /// No description provided for @perigee.
  ///
  /// In fr, this message translates to:
  /// **'Lune proche de la Terre : marées plus fortes'**
  String get perigee;

  /// No description provided for @proposeShop.
  ///
  /// In fr, this message translates to:
  /// **'Proposer un magasin ici'**
  String get proposeShop;

  /// No description provided for @shopName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du magasin'**
  String get shopName;

  /// No description provided for @phone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get phone;

  /// No description provided for @city.
  ///
  /// In fr, this message translates to:
  /// **'Ville'**
  String get city;

  /// No description provided for @send.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get send;

  /// No description provided for @contactUs.
  ///
  /// In fr, this message translates to:
  /// **'Nous contacter'**
  String get contactUs;

  /// No description provided for @tabForum.
  ///
  /// In fr, this message translates to:
  /// **'Forum'**
  String get tabForum;

  /// No description provided for @forumSub.
  ///
  /// In fr, this message translates to:
  /// **'Articles, photos et conseils des pêcheurs'**
  String get forumSub;

  /// No description provided for @forumEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun article pour l\'instant.'**
  String get forumEmpty;

  /// No description provided for @forumError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger le forum.'**
  String get forumError;

  /// No description provided for @forumDisabled.
  ///
  /// In fr, this message translates to:
  /// **'Le forum n\'est pas disponible dans cette version.'**
  String get forumDisabled;

  /// No description provided for @writeArticle.
  ///
  /// In fr, this message translates to:
  /// **'Écrire'**
  String get writeArticle;

  /// No description provided for @newArticle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvel article'**
  String get newArticle;

  /// No description provided for @articleTitle.
  ///
  /// In fr, this message translates to:
  /// **'Titre'**
  String get articleTitle;

  /// No description provided for @articleBody.
  ///
  /// In fr, this message translates to:
  /// **'Votre texte : spot, technique, prise, question…'**
  String get articleBody;

  /// No description provided for @category.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get category;

  /// No description provided for @addPhotos.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter des photos'**
  String get addPhotos;

  /// No description provided for @photoLimit.
  ///
  /// In fr, this message translates to:
  /// **'10 photos maximum'**
  String get photoLimit;

  /// No description provided for @publish.
  ///
  /// In fr, this message translates to:
  /// **'Publier'**
  String get publish;

  /// No description provided for @published.
  ///
  /// In fr, this message translates to:
  /// **'Article publié'**
  String get published;

  /// No description provided for @titleTooShort.
  ///
  /// In fr, this message translates to:
  /// **'Le titre doit faire au moins 3 caractères et le texte ne peut pas être vide.'**
  String get titleTooShort;

  /// No description provided for @comments.
  ///
  /// In fr, this message translates to:
  /// **'Commentaires'**
  String get comments;

  /// No description provided for @writeComment.
  ///
  /// In fr, this message translates to:
  /// **'Écrire un commentaire…'**
  String get writeComment;

  /// No description provided for @noComments.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de commentaire.'**
  String get noComments;

  /// No description provided for @loginToPost.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous pour publier, réagir et commenter.'**
  String get loginToPost;

  /// No description provided for @login.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get login;

  /// No description provided for @register.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get register;

  /// No description provided for @logout.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get logout;

  /// No description provided for @username.
  ///
  /// In fr, this message translates to:
  /// **'Nom d\'utilisateur'**
  String get username;

  /// No description provided for @usernameHint.
  ///
  /// In fr, this message translates to:
  /// **'3 à 30 caractères : lettres, chiffres, _ . -'**
  String get usernameHint;

  /// No description provided for @password.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get password;

  /// No description provided for @passwordHint.
  ///
  /// In fr, this message translates to:
  /// **'6 caractères minimum'**
  String get passwordHint;

  /// No description provided for @displayName.
  ///
  /// In fr, this message translates to:
  /// **'Nom affiché'**
  String get displayName;

  /// No description provided for @haveAccount.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai déjà un compte'**
  String get haveAccount;

  /// No description provided for @noAccount.
  ///
  /// In fr, this message translates to:
  /// **'Pas de compte ? Créez-en un'**
  String get noAccount;

  /// No description provided for @authFailed.
  ///
  /// In fr, this message translates to:
  /// **'Nom d\'utilisateur ou mot de passe incorrect.'**
  String get authFailed;

  /// No description provided for @usernameTaken.
  ///
  /// In fr, this message translates to:
  /// **'Ce nom d\'utilisateur est déjà pris.'**
  String get usernameTaken;

  /// No description provided for @accountSuspended.
  ///
  /// In fr, this message translates to:
  /// **'Ce compte est suspendu.'**
  String get accountSuspended;

  /// No description provided for @tooManyTries.
  ///
  /// In fr, this message translates to:
  /// **'Trop de tentatives, réessayez plus tard.'**
  String get tooManyTries;

  /// No description provided for @invalidForm.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez les champs du formulaire.'**
  String get invalidForm;

  /// No description provided for @serverUnreachable.
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion au serveur.'**
  String get serverUnreachable;

  /// No description provided for @loggedInAs.
  ///
  /// In fr, this message translates to:
  /// **'Connecté : {name}'**
  String loggedInAs(String name);

  /// No description provided for @account.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get account;

  /// No description provided for @deleteArticleQ.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cet article ?'**
  String get deleteArticleQ;

  /// No description provided for @searchForum.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher dans le forum'**
  String get searchForum;

  /// No description provided for @archive.
  ///
  /// In fr, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @catGeneral.
  ///
  /// In fr, this message translates to:
  /// **'Pêche générale'**
  String get catGeneral;

  /// No description provided for @catSurfcasting.
  ///
  /// In fr, this message translates to:
  /// **'Surfcasting'**
  String get catSurfcasting;

  /// No description provided for @catSpinning.
  ///
  /// In fr, this message translates to:
  /// **'Spinning'**
  String get catSpinning;

  /// No description provided for @catPole.
  ///
  /// In fr, this message translates to:
  /// **'Pêche au coup'**
  String get catPole;

  /// No description provided for @catBoat.
  ///
  /// In fr, this message translates to:
  /// **'Pêche en bateau'**
  String get catBoat;

  /// No description provided for @catQa.
  ///
  /// In fr, this message translates to:
  /// **'Questions'**
  String get catQa;

  /// No description provided for @catCatches.
  ///
  /// In fr, this message translates to:
  /// **'Belles prises'**
  String get catCatches;

  /// No description provided for @catVideos.
  ///
  /// In fr, this message translates to:
  /// **'Vidéos'**
  String get catVideos;

  /// No description provided for @mapLayers.
  ///
  /// In fr, this message translates to:
  /// **'Fond de carte'**
  String get mapLayers;

  /// No description provided for @mapStandard.
  ///
  /// In fr, this message translates to:
  /// **'Plan'**
  String get mapStandard;

  /// No description provided for @mapSatellite.
  ///
  /// In fr, this message translates to:
  /// **'Satellite'**
  String get mapSatellite;

  /// No description provided for @mapNight.
  ///
  /// In fr, this message translates to:
  /// **'Nuit'**
  String get mapNight;

  /// No description provided for @call.
  ///
  /// In fr, this message translates to:
  /// **'Appeler'**
  String get call;

  /// No description provided for @whatsapp.
  ///
  /// In fr, this message translates to:
  /// **'WhatsApp'**
  String get whatsapp;

  /// No description provided for @noPhone.
  ///
  /// In fr, this message translates to:
  /// **'Pas de numéro de téléphone'**
  String get noPhone;

  /// No description provided for @wxMapError.
  ///
  /// In fr, this message translates to:
  /// **'Données météo indisponibles.'**
  String get wxMapError;

  /// No description provided for @wxNow.
  ///
  /// In fr, this message translates to:
  /// **'Maintenant'**
  String get wxNow;

  /// No description provided for @wxDataNote.
  ///
  /// In fr, this message translates to:
  /// **'Modèles ECMWF, ICON, GFS, Météo-France. Zoomez pour plus de détails.'**
  String get wxDataNote;

  /// No description provided for @forumArticles.
  ///
  /// In fr, this message translates to:
  /// **'Articles'**
  String get forumArticles;

  /// No description provided for @forumQuestions.
  ///
  /// In fr, this message translates to:
  /// **'Questions'**
  String get forumQuestions;

  /// No description provided for @askQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Poser une question'**
  String get askQuestion;

  /// No description provided for @questionBadge.
  ///
  /// In fr, this message translates to:
  /// **'Question'**
  String get questionBadge;

  /// No description provided for @kindArticle.
  ///
  /// In fr, this message translates to:
  /// **'Article'**
  String get kindArticle;

  /// No description provided for @kindQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Question'**
  String get kindQuestion;

  /// No description provided for @aiImprove.
  ///
  /// In fr, this message translates to:
  /// **'Améliorer avec l\'IA'**
  String get aiImprove;

  /// No description provided for @aiImproved.
  ///
  /// In fr, this message translates to:
  /// **'Texte amélioré par l\'IA. Relisez-le avant de publier.'**
  String get aiImproved;

  /// No description provided for @aiUndo.
  ///
  /// In fr, this message translates to:
  /// **'Revenir à mon texte'**
  String get aiUndo;

  /// No description provided for @aiUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'L\'IA n\'est pas disponible pour le moment.'**
  String get aiUnavailable;

  /// No description provided for @aiAnswer.
  ///
  /// In fr, this message translates to:
  /// **'Réponse IA'**
  String get aiAnswer;

  /// No description provided for @aiAnswerNote.
  ///
  /// In fr, this message translates to:
  /// **'Réponse automatique de l\'assistant Sayad : à vérifier ; les pêcheurs du forum peuvent compléter.'**
  String get aiAnswerNote;

  /// No description provided for @mapTab.
  ///
  /// In fr, this message translates to:
  /// **'Carte'**
  String get mapTab;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
