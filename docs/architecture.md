# Architecture Technique - Bong Wallpaper

## 1. Objectif architecture
Fournir une architecture simple, testable et robuste pour une app menu bar macOS qui gere wallpapers online/offline.

## 2. Style d architecture
- Layered + ports/adapters leger:
  - `UI` (MenuBar)
  - `Domain` (regles metier)
  - `Infrastructure` (API, filesystem, system calls)

Avantages:
- isolation des dependances systeme
- tests unitaires faciles via protocoles
- evolution progressive sans rework lourd

## 3. Composants principaux
### 3.1 UI layer
- `MenuBarView`:
  - affiche actions `Previous`, `Next`, `Download`, `Rotate Daily`
- `MenuBarViewModel`:
  - orchestre actions utilisateur
  - expose etat (`isRotating`, `isDownloading`, `statusMessage`)

### 3.2 Domain layer
- `Wallpaper` (entite metier)
- `WallpaperProvider` (port lecture wallpapers)
- `WallpaperApplying` (port application desktop)
- `RotationPolicy`:
  - determine si rotation quotidienne doit etre executee

### 3.3 Infrastructure layer
- `WallpaperAPIClient`:
  - MVP Iteration 1: lit metadata et URLs directement depuis endpoint public Bing (`HPImageArchive.aspx`)
  - Iteration suivante: bascule vers gateway interne avec cache + CDN
- `WallpaperCache`:
  - sauvegarde fichiers images + metadata locale
- `BundledWallpaperProvider`:
  - lit wallpapers inclus dans bundle app
- `DesktopWallpaperApplier`:
  - encapsule `NSWorkspace.shared.setDesktopImageURL(...)`
- `DailyRotationScheduler`:
  - tache quotidienne locale (Timer/Background strategy simple)
- `PreferencesStore`:
  - persistance `UserDefaults` (`rotateDaily`, index, lastAppliedDate)
- `StartupCoordinator`:
  - sequence de demarrage (fetch/fallback/apply)

## 4. Flux principaux
### 4.1 Demarrage app
1. Charger preferences.
2. Construire catalog local (`cache + bundle`).
3. Si `Rotate Daily = ON` et pas encore applique aujourd hui:
- tenter refresh API
- merge dans cache
- appliquer wallpaper du jour (ou next logique)
4. Si echec reseau:
- fallback cache
- fallback bundle

### 4.2 Action `Next` / `Previous`
1. Lire index courant.
2. Calculer nouvel index dans catalogue local.
3. Appliquer image locale.
4. Sauvegarder index + lastAppliedDate.

### 4.3 Action `Download`
1. Fetch metadata API.
2. Telecharger images manquantes.
3. Verifier integrite minimale (taille/format).
4. Ecrire dans cache + metadata.
5. Rafraichir etat UI.

### 4.4 Rotation quotidienne
1. Scheduler se declenche a heure locale configuree (MVP: heure fixe, ex 09:00).
2. Controle anti-double execution sur meme date.
3. Appliquer wallpaper suivant ou du jour selon strategie.

## 5. Stockage local
### 5.1 Paths
- Cache images:
  - `~/Library/Application Support/BongWallpaper/Wallpapers/`
- Metadata cache:
  - `~/Library/Application Support/BongWallpaper/metadata.json`
- Preferences:
  - `UserDefaults` (suite standard)

### 5.2 Bundle initial
- `Resources/BundledWallpapers/` (min 5 images)
- Utilise uniquement en fallback ou au premier demarrage

## 6. Gestion d erreurs
- Reseau indisponible: ne jamais crasher, garder dernier wallpaper valide.
- Image invalide: ignorer entree et logguer erreur.
- Aucun wallpaper disponible: message menu clair, aucune action systeme destructive.

## 7. Securite et confiance
- Aucune action navigateur.
- Aucune modification systeme hors wallpaper desktop.
- Pas de collecte de donnees perso en MVP.

## 8. Observabilite
- Logging structure (console + unified logging):
  - startup
  - fetch API
  - cache hit/miss
  - apply success/failure
  - scheduler trigger

## 9. Testabilite
- Tous les services I/O exposes via protocoles.
- Mocks pour:
  - API client
  - cache store
  - wallpaper applier
  - clock/date provider
- Tests critiques:
  - fallback offline
  - anti double rotation quotidienne
  - navigation next/previous en boucle

## 10. Evolution post-MVP
- Introduire un gateway serveur devant Bing:
  - cache des N derniers wallpapers (par market/lang)
  - normalisation des metadata et politique de fallback
  - distribution des images via CDN
- Multi-screen policies.
- Interface de preferences avancee.
- Signature des payloads API / verification hash stricte.
- Notarization + distribution publique.

## 11. Reference integration Bing
- Documentation d integration et contrat pratique: `docs/bing-api.md`.
- MVP: client -> `global.bing.com` en direct.
- Cible: client -> gateway interne -> cache/CDN -> Bing.
