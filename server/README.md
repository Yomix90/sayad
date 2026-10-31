# Serveur Sayad (spots, magasins, tableau de bord)

API légère (Python FastAPI + SQLite) pour les **spots de pêche** et les **magasins** de l'application Sayad, avec un **tableau de bord de gestion** à l'adresse `/admin`.

## Tableau de bord (`/admin`)
Connexion avec le jeton `ADMIN_TOKEN`.
- **Statistiques** : spots et magasins validés, en attente, refusés.
- **À valider** : propositions envoyées depuis l'application, à valider ou refuser (une par une ou par lot).
- **Spots / Magasins** : recherche, filtre par statut, modification (nom, position, type, espèces, téléphone, magasin doré…), suppression, export CSV.
- **Carte** : tous les points sur une carte OpenStreetMap.
- **Import** : liste les fichiers du dossier `OLD_APP_DIR` (bases `.db`, CSV, JSON, GeoJSON). Pour chacun : aperçu, puis import dans les spots ou les magasins, validés ou en attente. On peut aussi **envoyer un fichier** depuis le navigateur. Les doublons (même nom à moins de 10 m) sont ignorés.

Les tables de l'ancienne application sont reconnues directement : `Masaid` (spots) et `Matajir` (magasins), colonnes `Name, Lat, Long, Icon, Inf`. Pour les magasins, le numéro de téléphone est extrait du champ `Inf`.

## API publique (utilisée par l'application)
| Méthode | Chemin | Rôle |
|---|---|---|
| GET | `/health` | état + nombre de spots et magasins validés |
| GET | `/spots?min_lat=&max_lat=&min_lon=&max_lon=` | spots validés de la zone |
| POST | `/spots` | proposer un spot `{name, lat, lon, kind, species}` (en attente) |
| GET | `/shops?…` | magasins validés de la zone |
| POST | `/shops` | proposer un magasin `{name, lat, lon, phone, city}` |

Limite : 5 propositions par heure et par adresse IP.

## Déploiement avec Dokploy
1. Dans Dokploy : **Create Service → Compose**.
2. **Provider** : GitHub, dépôt `Yomix90/sayad`, branche `main`, **Compose Path** : `./server/docker-compose.yml`.
3. **Environment** : ajoutez `ADMIN_TOKEN=` suivi d'un long mot de passe aléatoire (par exemple généré avec `openssl rand -hex 24`).
4. **Domains** : ajoutez votre domaine (par exemple `api.votresite.com`) sur le service `sayad-api`, **port 8100**, HTTPS activé (Let's Encrypt).
5. **Deploy**. Vérifiez `https://votre-domaine/health`, puis ouvrez `https://votre-domaine/admin`.

La base de données et les fichiers à importer sont dans le volume Docker `sayad-data` (dossier `/data` du conteneur). Ils sont conservés entre deux déploiements.

**Mettre les fichiers de l'ancienne application dans le serveur** : soit depuis le tableau de bord (onglet Import → Envoyer un fichier), soit en SSH :
```bash
docker cp ast.db <conteneur-sayad-api>:/data/old_app/
docker cp asx.db <conteneur-sayad-api>:/data/old_app/
```
Puis onglet **Import → Actualiser**.

Variante sans Compose : service **Application**, Build Type **Dockerfile**, Build Path `server`, port 8100, un volume monté sur `/data`, et la variable `ADMIN_TOKEN`.

## Sans Docker (VPS classique)
Voir `deploy/sayad-api.service` (systemd) et `deploy/nginx-sayad.conf` (proxy HTTPS).

## Import en ligne de commande
```bash
python import_spots.py --scan                                  # fichiers trouvés dans OLD_APP_DIR
python import_spots.py "../old app/ast.db" --dry-run           # aperçu
python import_spots.py "../old app/ast.db" --table Masaid
python import_spots.py "../old app/downloaded_dbs/asx.db" --into shops
```

## Brancher l'application
```bash
flutter build apk --release --split-per-abi --dart-define=SAYAD_API=https://votre-domaine --dart-define=STORMGLASS_KEY=...
```
Sans `SAYAD_API`, l'application fonctionne comme avant, sans spots partagés.

## Tests
```bash
python server/test_api.py
```
