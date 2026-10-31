# Sayad – صيّاد

Application Flutter (Android et iOS) de météo marine, marées et spots de pêche, en arabe, français et anglais.

## Fonctionnalités (version 0.4)
**Deux thèmes**, changés avec le bouton en haut à droite ou dans Réglages :
- **Moderne** : en-tête bleu océan avec vagues animées, cartes blanches, polices Manrope et Space Grotesk (IBM Plex Sans Arabic en arabe).
- **Ancien** : carte marine sur parchemin, rose des vents qui tourne, cadres dorés, frises, polices Cinzel et EB Garamond (Amiri en arabe).

**Accueil au premier lancement** : langue, région de pêche (ou GPS), thème.

**5 onglets** :
- **Aujourd'hui** : jauge d'indice de pêche (0–100), table solunaire sur 24 h, tuiles météo (vent, houle, eau, pression, air, ciel), soleil et lune.
- **Marées** : 7 jours, courbe avec pleines et basses mers, marnage, prochaine marée, point « maintenant ».
- **Carte** : OpenStreetMap et OpenSeaMap, filtres (mes spots, magasins et ports), fiche d'un point (distance, coordonnées, Naviguer via Google Maps, Sauvegarder, Prévisions).
- **Prévisions** : meilleur créneau du jour, tableau toutes les 3 h (vent et rafales, houle, état de la mer).
- **Outils** : Guide (8 nœuds, 4 hameçons), espèces, calendrier solunaire, journal de pêche, boussole et qibla, prière, réglages.

Les polices sont incluses dans `assets/fonts` : l'application fonctionne hors ligne.

## Sources de données
| Donnée | Source |
|---|---|
| Météo | Open-Meteo Forecast API |
| Vagues, température de l'eau, niveau de la mer (marées) | Open-Meteo Marine API |
| Cartes | OpenStreetMap, OpenSeaMap |
| Prière, qibla | bibliothèque `adhan`, calcul sur le téléphone |
| Lune | calcul sur le téléphone (`lib/services/astro.dart`) |

> Pour un usage commercial (publicités ou abonnement), il faut l'offre payante d'Open-Meteo et un fournisseur de tuiles de carte (MapTiler, Stadia…) : les serveurs `tile.openstreetmap.org` ne sont pas faits pour une application à grand public.

## Précision des données
- **Vent** : moyenne de 4 modèles (ICON, ECMWF IFS, Météo-France, GFS). Sur 3 jours d'observations horaires dans 9 aéroports côtiers marocains, l'erreur moyenne était de 3,5 km/h, contre 3,7 à 4,5 km/h pour chaque modèle seul. Température ±1,4 °C, pression ±0,6 hPa.
- **Marées** : avec une clé [WorldTides](https://www.worldtides.info), ce sont des prédictions harmoniques au-dessus du zéro des cartes, comme les annuaires. Sans clé, l'application utilise le niveau de la mer modélisé par Open-Meteo, qui peut être décalé d'1 à 2 h (mesuré à Casablanca), et l'indique à l'écran.

Compiler avec la clé de marées :
```
flutter build apk --release --split-per-abi --dart-define=WORLDTIDES_KEY=votre_cle
```
Ou avec Stormglass (offre gratuite : 10 requêtes par jour, usage non commercial). L'application fait 1 requête par zone d'environ 11 km, valable une semaine environ :
```
flutter build apk --release --split-per-abi --dart-define=STORMGLASS_KEY=votre_cle
```
Les réponses sont gardées 24 h par lieu pour économiser les crédits. Avec les deux clés, WorldTides est utilisé en premier.

## Lancer le projet
```
flutter pub get
flutter run
```
Les traductions sont dans `lib/l10n/app_*.arb`. Après une modification : `flutter gen-l10n`.

## Aperçus
Images des écrans dans `test/previews/`, à régénérer avec :
```
flutter test test/preview_test.dart --update-goldens --tags preview --run-skipped
```

## Structure
```
lib/
  main.dart                 navigation et langues
  theme.dart                couleurs, mode clair et sombre
  l10n/                     traductions ar / fr / en
  services/
    forecast_service.dart   appels Open-Meteo, calcul des marées
    astro.dart              lune, prière, qibla, indice de pêche
    app_state.dart          langue, position, spots enregistrés
  screens/                  Aujourd'hui, Carte, Prière, Réglages
  widgets/common.dart       cartes, flèches de vent, icônes météo
```
