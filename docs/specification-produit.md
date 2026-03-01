# Specification Produit - Bong Wallpaper (MVP)

## 1. Objectif
Construire une application macOS native, non intrusive, qui change le fond d ecran depuis Bing, avec fallback local offline.

## 2. Problemes a resoudre
- Les apps existantes sont intrusives (navigation forcee, changements non demandes).
- Le user veut un controle simple depuis la menu bar.
- Le user veut un fonctionnement robuste meme sans internet au demarrage.

## 3. Principes produit
- Controle utilisateur prioritaire.
- Zero comportement cache.
- Offline-first au demarrage.
- UX minimaliste et rapide.

## 4. Perimetre MVP
### 4.1 Inclus
- App menu bar native macOS.
- Menu avec actions:
  - `Previous`
  - `Next`
  - `Download`
  - switch `Rotate Daily` (on/off)
- Application du wallpaper sur le bureau principal.
- Source de wallpapers:
  - MVP Iteration 1: endpoint public Bing appele directement par le client
  - Architecture cible: gateway serveur avec cache + CDN
  - wallpapers bundles dans l app (fallback)
  - cache local telecharge
- Persistance des preferences (`Rotate Daily`, index courant, dernier jour applique).

### 4.2 Exclu (MVP)
- UI fenetre complexe (galerie, crop, filtres).
- Multi-screen avec regles avancees.
- Sync cloud.
- Telemetrie avancee.

## 5. User stories
- En tant qu utilisateur, je veux changer au wallpaper precedent/suivant depuis la menu bar.
- En tant qu utilisateur, je veux telecharger de nouveaux wallpapers a la demande.
- En tant qu utilisateur, je veux activer/desactiver la rotation quotidienne avec un switch.
- En tant qu utilisateur, je veux que l app fonctionne sans internet au demarrage.
- En tant qu utilisateur, je veux que l app ne modifie jamais mon navigateur, homepage, ni autre parametre systeme non lie au wallpaper.

## 6. Exigences fonctionnelles
- `FR-001` L app s execute en menu bar et n ouvre pas de fenetre principale au demarrage.
- `FR-002` Un clic sur l icone ouvre un menu avec les 4 actions MVP.
- `FR-003` `Previous` applique le wallpaper precedent dans la liste disponible locale.
- `FR-004` `Next` applique le wallpaper suivant dans la liste disponible locale.
- `FR-005` `Download` declenche un refresh depuis l API, met en cache local, sans bloquer l UI.
- `FR-006` `Rotate Daily` active/desactive la tache quotidienne locale.
- `FR-007` Au lancement:
  - Si `Rotate Daily = ON` et aucun wallpaper applique ce jour: tenter fetch API puis appliquer.
  - Si API indisponible: appliquer depuis cache local, sinon depuis bundle.
- `FR-008` Les erreurs reseau ne cassent pas l app; message d etat discret dans le menu.
- `FR-009` L app sauvegarde preferences et index courant entre sessions.
- `FR-010` Aucun changement de parametres hors wallpaper (navigateur, moteur recherche, startup browser, etc.).

## 7. Exigences non fonctionnelles
- `NFR-001` Temps d ouverture menu < 100 ms sur machine recente.
- `NFR-002` Changement wallpaper manuel < 2 s avec image deja locale.
- `NFR-003` Pas de crash si API down, timeout ou image invalide.
- `NFR-004` Code testable via protocoles pour services I/O.
- `NFR-005` Logs locaux lisibles pour debug (niveau info/error).

## 8. Donnees et contrats (proposition)
### 8.1 Modele wallpaper
- `id: String`
- `title: String`
- `imageURL: URL`
- `sha256: String?`
- `publishedAt: Date?`
- `localPath: String?`
- `source: bundled | cache | remote`

### 8.2 Endpoints API proposes
- MVP Iteration 1 (direct):
  - `GET https://global.bing.com/HPImageArchive.aspx?format=js&idx=0&n=9&pid=hp&FORM=BEHPTB&uhd=1&uhdwidth=3840&uhdheight=2160&setmkt={market}&setlang=en`
- Iteration suivante (gateway interne + CDN):
  - `GET /v1/wallpapers/today`
  - `GET /v1/wallpapers?cursor=...`
  - `GET /v1/wallpapers/{id}`

Recommandation: retourner metadata + URL image, et utiliser `ETag`/`If-None-Match` pour eviter des downloads inutiles.

### 8.3 Usage de Bing (section dediee)
- Voir le guide detaille: `docs/bing-api.md`.
- Hostname MVP fige: `https://global.bing.com`.
- Les hostnames `www.bing.com` et `cn.bing.com` sont identifies mais hors scope MVP.

## 9. Comportement offline
- Bundle initial: minimum 5 wallpapers de qualite.
- Au demarrage offline:
  - priorite cache local
  - sinon bundle
- Si aucune image valide: afficher erreur menu `No wallpaper available` et garder wallpaper actuel systeme.

## 10. UX et contraintes de confiance
- L app doit etre explicite sur chaque action utilisateur.
- Aucune ouverture automatique de navigateur.
- Aucune modification homepage/search engine.
- Option de lancement au login (post-MVP), desactivee par defaut.

## 11. Criteres d acceptance MVP
- L app demarre en menu bar et reste stable > 24 h.
- Les boutons `Previous`/`Next` changent effectivement le wallpaper.
- `Download` ajoute de nouveaux wallpapers en cache local si API disponible.
- `Rotate Daily` applique au plus 1 wallpaper/jour (sauf actions manuelles).
- En mode offline, l app reste utilisable avec bundle/cache.
- Aucun comportement intrusif hors perimetre wallpaper.
