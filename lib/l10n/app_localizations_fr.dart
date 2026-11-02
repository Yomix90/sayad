// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Sayad';

  @override
  String get tabToday => 'Aujourd\'hui';

  @override
  String get tabMap => 'Carte';

  @override
  String get tabPrayer => 'Prière';

  @override
  String get tabSettings => 'Réglages';

  @override
  String get loading => 'Chargement…';

  @override
  String get retry => 'Réessayer';

  @override
  String get errorLoad =>
      'Impossible de charger les données. Vérifiez votre connexion.';

  @override
  String get locationDenied =>
      'Localisation refusée : position par défaut utilisée (Casablanca).';

  @override
  String get fishingIndex => 'Indice de pêche';

  @override
  String get fishingPoor => 'Faible';

  @override
  String get fishingFair => 'Moyen';

  @override
  String get fishingGood => 'Bon';

  @override
  String get fishingExcellent => 'Excellent';

  @override
  String get weather => 'Météo';

  @override
  String get sea => 'Mer';

  @override
  String get wind => 'Vent';

  @override
  String get gusts => 'Rafales';

  @override
  String get pressure => 'Pression';

  @override
  String get temperature => 'Température';

  @override
  String get waves => 'Vagues';

  @override
  String get wavePeriod => 'Période';

  @override
  String get waterTemp => 'Eau';

  @override
  String get tides => 'Marées';

  @override
  String get highTide => 'Pleine mer';

  @override
  String get lowTide => 'Basse mer';

  @override
  String get noMarineData =>
      'Pas de données marines pour ce point (zone terrestre).';

  @override
  String get sunMoon => 'Soleil et lune';

  @override
  String get sunrise => 'Lever du soleil';

  @override
  String get sunset => 'Coucher du soleil';

  @override
  String get moonPhase => 'Phase de lune';

  @override
  String get illumination => 'Illumination';

  @override
  String get moonNew => 'Nouvelle lune';

  @override
  String get moonWaxingCrescent => 'Premier croissant';

  @override
  String get moonFirstQuarter => 'Premier quartier';

  @override
  String get moonWaxingGibbous => 'Gibbeuse croissante';

  @override
  String get moonFull => 'Pleine lune';

  @override
  String get moonWaningGibbous => 'Gibbeuse décroissante';

  @override
  String get moonLastQuarter => 'Dernier quartier';

  @override
  String get moonWaningCrescent => 'Dernier croissant';

  @override
  String get next24h => 'Prochaines 24 h';

  @override
  String get mySpots => 'Mes spots';

  @override
  String get addSpotHint => 'Appui long sur la carte pour ajouter un spot';

  @override
  String get addSpot => 'Ajouter un spot';

  @override
  String get spotName => 'Nom du spot';

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Enregistrer';

  @override
  String get delete => 'Supprimer';

  @override
  String get forecastHere => 'Prévisions ici';

  @override
  String get myPosition => 'Ma position';

  @override
  String get prayerTimes => 'Heures de prière';

  @override
  String get fajr => 'Fajr';

  @override
  String get sunrisePrayer => 'Chourouq';

  @override
  String get dhuhr => 'Dhohr';

  @override
  String get asr => 'Asr';

  @override
  String get maghrib => 'Maghrib';

  @override
  String get isha => 'Icha';

  @override
  String get qibla => 'Direction de la qibla';

  @override
  String qiblaDegrees(String deg) {
    return '$deg° depuis le nord';
  }

  @override
  String get language => 'Langue';

  @override
  String get systemLanguage => 'Langue du système';

  @override
  String get about => 'À propos';

  @override
  String get dataSources =>
      'Données : Open-Meteo (météo et mer), OpenStreetMap et OpenSeaMap (cartes). Les marées sont un modèle : ne les utilisez pas pour la navigation.';

  @override
  String get kmh => 'km/h';

  @override
  String get hpa => 'hPa';

  @override
  String get meters => 'm';

  @override
  String get seconds => 's';

  @override
  String get tabForecast => 'Prévisions';

  @override
  String get tabTools => 'Outils';

  @override
  String get hour => 'Heure';

  @override
  String get humidity => 'Humidité';

  @override
  String get current => 'Courant';

  @override
  String get tidalRange => 'Marnage';

  @override
  String get tidesDisclaimer =>
      'Les marées viennent d\'un modèle mondial et peuvent différer de la réalité près des côtes. Ne pas utiliser pour la navigation.';

  @override
  String get solunarCalendar => 'Calendrier solunaire';

  @override
  String get solunarHelp =>
      'Périodes majeures : lune au zénith ou au nadir (2 h). Périodes mineures : lever et coucher de la lune (1 h). Horaires approximatifs.';

  @override
  String get major => 'Majeure';

  @override
  String get minor => 'Mineure';

  @override
  String get compass => 'Boussole';

  @override
  String get noCompassSensor =>
      'Votre téléphone n\'a pas de capteur de boussole.';

  @override
  String get compassHelp =>
      'Tenez le téléphone à plat, loin du métal. Pour calibrer, faites un 8 avec le téléphone.';

  @override
  String get knots => 'Nœuds de pêche';

  @override
  String get species => 'Espèces';

  @override
  String get inSeason => 'en saison';

  @override
  String get sizeDisclaimer =>
      'Les tailles minimales sont indicatives. Vérifiez la réglementation locale avant de garder un poisson.';

  @override
  String get bestSeason => 'Meilleurs mois';

  @override
  String get habitat => 'Habitat';

  @override
  String get bait => 'Appâts';

  @override
  String get technique => 'Technique';

  @override
  String get minSize => 'Taille minimale';

  @override
  String get catchLog => 'Journal de pêche';

  @override
  String get addCatch => 'Ajouter une prise';

  @override
  String get noCatches =>
      'Aucune prise pour l\'instant. Enregistrez vos prises pour découvrir vos meilleures conditions.';

  @override
  String get statistics => 'Statistiques';

  @override
  String get totalCatches => 'Prises';

  @override
  String get biggestCatch => 'La plus lourde';

  @override
  String get topSpecies => 'Espèce n°1';

  @override
  String get otherSpecies => 'Autre espèce…';

  @override
  String get speciesName => 'Nom de l\'espèce';

  @override
  String get weightKg => 'Poids (kg)';

  @override
  String get lengthCm => 'Taille (cm)';

  @override
  String get note => 'Note (appât, technique…)';

  @override
  String get catchAutoInfo =>
      'La date, la position, le vent, les vagues et la phase de lune sont enregistrés automatiquement.';

  @override
  String get placesNearby => 'Magasins et ports proches';

  @override
  String get placesError =>
      'Impossible de charger les lieux. Réessayez plus tard.';

  @override
  String get fishingShop => 'Magasin de pêche';

  @override
  String get port => 'Port';

  @override
  String get marina => 'Marina';

  @override
  String get slipway => 'Cale de mise à l\'eau';

  @override
  String get seeAll => 'Tout voir';

  @override
  String placesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lieux trouvés',
      one: '1 lieu trouvé',
      zero: 'Aucun lieu trouvé ici',
    );
    return '$_temp0';
  }

  @override
  String get subtitle => 'Guide du pêcheur';

  @override
  String get changeTheme => 'Changer de thème';

  @override
  String get morocco => 'Maroc';

  @override
  String get gpsOn => 'GPS actif';

  @override
  String get gpsOff => 'GPS coupé';

  @override
  String get condPoor => 'Conditions faibles';

  @override
  String get condFair => 'Conditions moyennes';

  @override
  String get condGood => 'Bonnes conditions';

  @override
  String get condExcellent => 'Excellentes conditions';

  @override
  String majorNow(String end) {
    return 'Période majeure en cours jusqu\'à $end.';
  }

  @override
  String nextMajor(String range) {
    return 'Prochaine période majeure : $range.';
  }

  @override
  String get indexNote =>
      'L\'activité dépend de la lune, de la pression, du vent et de la mer.';

  @override
  String pressureRising(String v) {
    return 'En hausse (+$v)';
  }

  @override
  String pressureFalling(String v) {
    return 'En baisse (−$v)';
  }

  @override
  String get pressureSteady => 'Stable';

  @override
  String get solunarTable => 'Table solunaire';

  @override
  String get h24 => '24 h';

  @override
  String get majorPeriod => 'Période majeure';

  @override
  String get minorPeriod => 'Période mineure';

  @override
  String get swell => 'Houle';

  @override
  String get noMarineShort => 'Pas de données marines';

  @override
  String get surfaceTemp => 'Température de surface';

  @override
  String get airTemp => 'Air';

  @override
  String get wxClear => 'Dégagé';

  @override
  String get wxCloudy => 'Nuageux';

  @override
  String get wxFog => 'Brouillard';

  @override
  String get wxRain => 'Pluie';

  @override
  String get wxSnow => 'Neige';

  @override
  String get wxStorm => 'Orage';

  @override
  String get sun => 'Soleil';

  @override
  String get moon => 'Lune';

  @override
  String get rise => 'Lever';

  @override
  String get set => 'Coucher';

  @override
  String get days7 => '7 jours';

  @override
  String get hwShort => 'PM';

  @override
  String get lwShort => 'BM';

  @override
  String get nextTide => 'Prochaine marée';

  @override
  String inDuration(String d) {
    return 'dans $d';
  }

  @override
  String get upcoming => 'À venir';

  @override
  String get marineForecast => 'Prévisions marines';

  @override
  String bestWindow(String range, String state) {
    return 'Meilleur créneau : $range · mer $state';
  }

  @override
  String get temperatureShort => 'Temp.';

  @override
  String get calm => 'Calme';

  @override
  String get moderate => 'Modérée';

  @override
  String get rough => 'Agitée';

  @override
  String spotsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count spots',
      one: '1 spot',
      zero: 'Aucun spot',
    );
    return '$_temp0';
  }

  @override
  String get selectedPoint => 'Point sélectionné';

  @override
  String get pointKind => 'Point de la carte';

  @override
  String get mySpot => 'Mon spot';

  @override
  String get all => 'Tous';

  @override
  String get placesFilter => 'Magasins & ports';

  @override
  String get saved => 'Sauvegardé';

  @override
  String get direct => 'Directe';

  @override
  String get coords => 'Position';

  @override
  String get navigate => 'Naviguer';

  @override
  String get spotSaved => 'Spot sauvegardé ✓';

  @override
  String get guide => 'Guide';

  @override
  String get knotsAndHooks => 'Nœuds & hameçons';

  @override
  String get knotsShort => 'Nœuds';

  @override
  String get hooks => 'Hameçons';

  @override
  String get use => 'Usage';

  @override
  String get difficulty => 'Difficulté';

  @override
  String get easy => 'Facile';

  @override
  String get medium => 'Moyen';

  @override
  String get steps => 'Étapes';

  @override
  String get tip => 'Conseil du pêcheur';

  @override
  String get speciesSub => 'Saisons, appâts et techniques';

  @override
  String get solunarSub => '30 jours de périodes';

  @override
  String get catchLogSub => 'Vos prises et leurs conditions';

  @override
  String get compassSub => 'Cap et qibla';

  @override
  String get prayerSub => 'Selon votre position';

  @override
  String get settingsSub => 'Langue, thème, région';

  @override
  String stepOf(int a, int b) {
    return 'Étape $a / $b';
  }

  @override
  String get later => 'Plus tard';

  @override
  String get continueLabel => 'Continuer';

  @override
  String get start => 'Commencer';

  @override
  String get chooseLanguage => 'Choisissez votre langue';

  @override
  String get chooseLanguageSub =>
      'L\'interface et le guide sont entièrement traduits.';

  @override
  String get chooseRegion => 'Votre région de pêche';

  @override
  String get chooseRegionSub =>
      'Elle sert pour les prévisions et les marées quand le GPS est coupé.';

  @override
  String get useGps => 'Utiliser ma position GPS';

  @override
  String get useGpsSub => 'Le plus précis, surtout en mer';

  @override
  String get chooseStyle => 'Choisissez le style';

  @override
  String get chooseStyleSub =>
      'Modifiable à tout moment avec le bouton en haut de l\'écran.';

  @override
  String get styleModern => 'Moderne';

  @override
  String get styleModernSub => 'Bleu océan, clair et lisible';

  @override
  String get styleClassic => 'Ancien';

  @override
  String get styleClassicSub => 'Carte marine ancienne sur parchemin';

  @override
  String get appearance => 'Apparence';

  @override
  String get fishingRegion => 'Région de pêche';

  @override
  String get replayWelcome => 'Revoir l\'écran d\'accueil';

  @override
  String get loadingTides => 'Lecture des marées…';

  @override
  String get loadingMoon => 'Calcul de la lune…';

  @override
  String get loadingSpots => 'Préparation des spots…';

  @override
  String get tideSourcePrecise => 'Prévisions précises (WorldTides)';

  @override
  String get tideSourceModel =>
      'Modèle approximatif (écart possible de 1 à 2 h)';

  @override
  String get tidesDisclaimerPrecise =>
      'Hauteurs au-dessus du zéro des cartes (plus basse mer astronomique), comme les annuaires de marée. Pour la navigation, utilisez toujours les documents officiels.';

  @override
  String get tideSourceStormglass => 'Prévisions précises (Stormglass)';

  @override
  String tideSourceCorrected(String port) {
    return 'Précis : corrigé sur la table du port de $port';
  }

  @override
  String get tideSourceUncalibrated =>
      'Stormglass non calibré ici (écart possible jusqu\'à 1 h)';

  @override
  String get chooseCity => 'Choisir une ville côtière';

  @override
  String get searchCity => 'Rechercher une ville…';

  @override
  String get noCityFound => 'Aucune ville trouvée.';

  @override
  String get changeCity => 'Appuyez pour changer de ville';

  @override
  String get coastMediterranean => 'Méditerranée';

  @override
  String get coastAtlanticNorth => 'Atlantique nord';

  @override
  String get coastAtlanticCentre => 'Atlantique centre';

  @override
  String get coastSouss => 'Souss';

  @override
  String get coastSahara => 'Sahara';

  @override
  String get targetDistance => 'Distance jusqu\'au spot';

  @override
  String get targetBearing => 'Cap';

  @override
  String get targetSpot => 'Spot visé';

  @override
  String get waitingGps => 'Recherche du signal GPS…';

  @override
  String get targetHelp =>
      'Suivez la flèche. Fonctionne sans internet ni carte, avec le GPS et la boussole seulement.';

  @override
  String get targetNoCompass =>
      'Pas de boussole : tenez le téléphone le haut vers le nord.';

  @override
  String get guideOffline => 'Guider (hors ligne)';

  @override
  String get springTide => 'Vives-eaux (حمل)';

  @override
  String get neapTide => 'Mortes-eaux (كساد)';

  @override
  String get midTide => 'Marée moyenne';

  @override
  String get hijriCalendar => 'Calendrier hégirien';

  @override
  String get hijriHelp =>
      'Le Maroc suit l\'observation du croissant, souvent un jour après le calcul. Choisissez la date correcte.';

  @override
  String get hijriMorocco => 'Maroc (par défaut)';

  @override
  String get hijriUmmAlQura => 'Calcul (Umm al-Qura)';

  @override
  String get weatherMap => 'Carte météo';

  @override
  String get weatherMapSub => 'Vent, vagues, pluie animés';

  @override
  String get tips => 'Conseils';

  @override
  String get tipsSub => 'Moments de pêche, marées, sécurité';

  @override
  String get communitySpots => 'Spots de pêche';

  @override
  String get communitySpot => 'Spot de pêche';

  @override
  String get shareSpot => 'Partager avec tous';

  @override
  String get shareSpotSub => 'Visible après validation';

  @override
  String get spotShared => 'Envoyé, en attente de validation ✓';

  @override
  String get spotShareFailed => 'Envoi impossible, réessayez plus tard';

  @override
  String get bigTides => 'Grandes marées de l\'année';

  @override
  String get bigTidesSub => 'Meilleurs jours pour les appâts';

  @override
  String get bigTidesHelp =>
      'Jours de vives-eaux (1,5 jour après la nouvelle et la pleine lune). Les plus fortes sont mises en avant : la mer y descend le plus bas, idéal pour ramasser les appâts et pêcher les bordures.';

  @override
  String get bigTideTop => 'parmi les plus fortes de l\'année';

  @override
  String get coefficientShort => 'coef.';

  @override
  String get coefficientDisclaimer =>
      'Coefficient calculé à partir des positions de la Lune et du Soleil (≈). Le classement des jours est fiable ; la valeur est approximative.';

  @override
  String get sky => 'Soleil et lune dans le ciel';

  @override
  String get skySub => 'Direction et hauteur toute la journée';

  @override
  String get skyNow => 'Maintenant';

  @override
  String get skyHelp =>
      'Le cercle extérieur est l\'horizon, le centre est au-dessus de vous. Jaune : trajet du soleil, gris : trajet de la lune.';

  @override
  String get skyHeight => 'Hauteur';

  @override
  String get skyDirection => 'Direction';

  @override
  String get skyDistance => 'Distance';

  @override
  String get perigee => 'Lune proche de la Terre : marées plus fortes';

  @override
  String get proposeShop => 'Proposer un magasin ici';

  @override
  String get shopName => 'Nom du magasin';

  @override
  String get phone => 'Téléphone';

  @override
  String get city => 'Ville';

  @override
  String get send => 'Envoyer';

  @override
  String get contactUs => 'Nous contacter';

  @override
  String get tabForum => 'Forum';

  @override
  String get forumSub => 'Articles, photos et conseils des pêcheurs';

  @override
  String get forumEmpty => 'Aucun article pour l\'instant.';

  @override
  String get forumError => 'Impossible de charger le forum.';

  @override
  String get forumDisabled =>
      'Le forum n\'est pas disponible dans cette version.';

  @override
  String get writeArticle => 'Écrire';

  @override
  String get newArticle => 'Nouvel article';

  @override
  String get articleTitle => 'Titre';

  @override
  String get articleBody => 'Votre texte : spot, technique, prise, question…';

  @override
  String get category => 'Catégorie';

  @override
  String get addPhotos => 'Ajouter des photos';

  @override
  String get photoLimit => '10 photos maximum';

  @override
  String get publish => 'Publier';

  @override
  String get published => 'Article publié';

  @override
  String get titleTooShort =>
      'Le titre doit faire au moins 3 caractères et le texte ne peut pas être vide.';

  @override
  String get comments => 'Commentaires';

  @override
  String get writeComment => 'Écrire un commentaire…';

  @override
  String get noComments => 'Pas encore de commentaire.';

  @override
  String get loginToPost => 'Connectez-vous pour publier, réagir et commenter.';

  @override
  String get login => 'Se connecter';

  @override
  String get register => 'Créer un compte';

  @override
  String get logout => 'Se déconnecter';

  @override
  String get username => 'Nom d\'utilisateur';

  @override
  String get usernameHint => '3 à 30 caractères : lettres, chiffres, _ . -';

  @override
  String get password => 'Mot de passe';

  @override
  String get passwordHint => '6 caractères minimum';

  @override
  String get displayName => 'Nom affiché';

  @override
  String get haveAccount => 'J\'ai déjà un compte';

  @override
  String get noAccount => 'Pas de compte ? Créez-en un';

  @override
  String get authFailed => 'Nom d\'utilisateur ou mot de passe incorrect.';

  @override
  String get usernameTaken => 'Ce nom d\'utilisateur est déjà pris.';

  @override
  String get accountSuspended => 'Ce compte est suspendu.';

  @override
  String get tooManyTries => 'Trop de tentatives, réessayez plus tard.';

  @override
  String get invalidForm => 'Vérifiez les champs du formulaire.';

  @override
  String get serverUnreachable => 'Pas de connexion au serveur.';

  @override
  String loggedInAs(String name) {
    return 'Connecté : $name';
  }

  @override
  String get account => 'Compte';

  @override
  String get deleteArticleQ => 'Supprimer cet article ?';

  @override
  String get searchForum => 'Rechercher dans le forum';

  @override
  String get archive => 'Archive';

  @override
  String get catGeneral => 'Pêche générale';

  @override
  String get catSurfcasting => 'Surfcasting';

  @override
  String get catSpinning => 'Spinning';

  @override
  String get catPole => 'Pêche au coup';

  @override
  String get catBoat => 'Pêche en bateau';

  @override
  String get catQa => 'Questions';

  @override
  String get catCatches => 'Belles prises';

  @override
  String get catVideos => 'Vidéos';

  @override
  String get mapLayers => 'Fond de carte';

  @override
  String get mapStandard => 'Plan';

  @override
  String get mapSatellite => 'Satellite';

  @override
  String get mapNight => 'Nuit';

  @override
  String get call => 'Appeler';

  @override
  String get whatsapp => 'WhatsApp';

  @override
  String get noPhone => 'Pas de numéro de téléphone';

  @override
  String get wxMapError => 'Données météo indisponibles.';

  @override
  String get wxNow => 'Maintenant';

  @override
  String get wxDataNote =>
      'Modèles ECMWF, ICON, GFS, Météo-France. Zoomez pour plus de détails.';

  @override
  String get forumArticles => 'Articles';

  @override
  String get forumQuestions => 'Questions';

  @override
  String get askQuestion => 'Poser une question';

  @override
  String get questionBadge => 'Question';

  @override
  String get kindArticle => 'Article';

  @override
  String get kindQuestion => 'Question';

  @override
  String get aiImprove => 'Améliorer avec l\'IA';

  @override
  String get aiImproved =>
      'Texte amélioré par l\'IA. Relisez-le avant de publier.';

  @override
  String get aiUndo => 'Revenir à mon texte';

  @override
  String get aiUnavailable => 'L\'IA n\'est pas disponible pour le moment.';
}
