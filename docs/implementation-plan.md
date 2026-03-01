# Plan d Implementation - Bong Wallpaper

## 1. Strategie generale
Approche incremental MVP:
1. Base menu bar + wallpaper local
2. API + cache
3. Rotation quotidienne
4. Stabilisation + tests

## 2. Planning par phases

## Phase 0 - Bootstrap projet (0.5 a 1 jour)
### Objectifs
- Initialiser projet Xcode macOS SwiftUI.
- Configurer app menu bar (agent, pas Dock).
- Poser structure dossiers et protocoles de base.

### Sorties attendues
- Projet compilable.
- Icone menu bar visible.
- CI locale build debug OK.

### Acceptance
- `xcodebuild ... build` passe.
- App lancee sans crash.

## Phase 1 - Coeur local offline (1 a 2 jours)
### Objectifs
- Charger wallpapers bundle.
- Implementer `Next` et `Previous`.
- Appliquer wallpaper via service systeme.

### Sorties attendues
- Boutons menu fonctionnels sur wallpapers locaux.
- Index persiste entre relances.

### Acceptance
- Navigation en boucle sur liste locale.
- Wallpaper change reellement sur desktop.

## Phase 2 - Download + API + cache (2 a 3 jours)
### Objectifs
- MVP Iteration 1: appeler Bing en direct (`https://global.bing.com/HPImageArchive.aspx?...`).
- Telecharger et stocker images localement.
- Fusionner catalogue `cache + bundle`.
- Appliquer les regles du guide `docs/bing-api.md` (URL, parsing, fallback, timeout/retry).

### Sorties attendues
- Action `Download` stable.
- Fallback automatique si reseau indisponible.

### Acceptance
- Sans internet, app reste utilisable.
- Avec internet, nouveaux wallpapers sont caches.

### Note architecture cible
- Iteration suivante: ajouter un gateway serveur avec cache des N derniers wallpapers + CDN.
- Le client macOS consommera ce gateway au lieu de Bing direct pour stabilite et performance.

## Phase 3 - Rotate Daily (1 a 2 jours)
### Objectifs
- Ajouter switch `Rotate Daily`.
- Implementer scheduler local quotidien.
- Bloquer double execution le meme jour.

### Sorties attendues
- Rotation quotidienne respectee.
- Persistance etat `Rotate Daily`.

### Acceptance
- Si ON: un changement automatique/jour.
- Si OFF: aucun changement automatique.

## Phase 4 - Durcissement qualite (1 a 2 jours)
### Objectifs
- Ajouter tests unitaires critiques.
- Ameliorer logs et messages d erreur.
- Verifier scenarios de crash et reprise.

### Sorties attendues
- Suite tests minimum stable.
- Comportement degrade propre en erreurs.

### Acceptance
- Tests critiques verts.
- Aucun comportement intrusif detecte.

## 3. Backlog technique detaille (ordre recommande)
1. Creer modele `Wallpaper` + protocoles provider/applier.
2. Implementer `BundledWallpaperProvider`.
3. Implementer `DesktopWallpaperApplier`.
4. Construire `MenuBarViewModel` avec commandes previous/next.
5. Persister index + flags via `PreferencesStore`.
6. Ajouter `WallpaperAPIClient`.
7. Ajouter `WallpaperCache` (fichiers + metadata json).
8. Brancher action `Download`.
9. Ajouter `DailyRotationScheduler`.
10. Ajouter tests unitaires et integration mocks.

## 4. Plan de test minimum
- `T1` First launch offline avec bundle uniquement.
- `T2` Navigation previous/next apres relance app.
- `T3` Download online puis utilisation offline.
- `T4` Rotate Daily ON, execution unique sur meme date.
- `T5` Rotate Daily OFF, aucune execution auto.
- `T6` API timeout -> app stable + message clair.

## 5. Risques et mitigations
- API instable:
  - Mitigation: timeout court + retry limite + fallback local.
- Fichiers images corrompus:
  - Mitigation: validation format/size avant ajout catalogue.
- Changement wallpaper qui echoue sur certaines configs:
  - Mitigation: capture erreur + rollback logique + logs.
- Scheduler non fiable en veille prolongee:
  - Mitigation: verifier au demarrage si jour non traite.

## 6. Definition of Done (MVP)
- Les 4 controles menu sont implementes et stables.
- L app marche online et offline.
- La rotation quotidienne est fiable au niveau utilisateur.
- Aucune fonctionnalite intrusive hors changement wallpaper.
- Docs techniques a jour (`specification`, `architecture`, `setup`).

## 7. Etape immediate suivante
Demarrer `Phase 0` puis `Phase 1` pour obtenir rapidement une version locale fonctionnelle sans dependance reseau.
