# Integration Bing - Guide pratique (MVP)

## 1. Contexte
Pour le MVP (Iteration 1), le client macOS interroge directement l endpoint public Bing pour recuperer metadata + images.

Architecture cible (iteration suivante): gateway interne + cache + CDN.

## 2. Hostnames observes
Dans les projets de reference (`exemples/`), on retrouve plusieurs hostnames Bing:
- `https://www.bing.com` (local/standard)
- `https://global.bing.com` (global)
- `https://cn.bing.com` (chine)

Decision MVP:
- utiliser uniquement `https://global.bing.com`
- ne pas gerer de switch hostname dans le client pour l instant

## 3. Endpoint retenu
Template MVP:

`https://global.bing.com/HPImageArchive.aspx?format=js&idx=0&n=9&pid=hp&FORM=BEHPTB&uhd=1&uhdwidth=3840&uhdheight=2160&setmkt={market}&setlang=en`

Exemple:

`https://global.bing.com/HPImageArchive.aspx?format=js&idx=0&n=9&pid=hp&FORM=BEHPTB&uhd=1&uhdwidth=3840&uhdheight=2160&setmkt=en-US&setlang=en`

## 4. Parametres utiles
- `format=js`: reponse JSON
- `idx=0`: image du jour en tete
- `n=9`: nombre d images demandees (max pratique du MVP)
- `uhd=1`, `uhdwidth=3840`, `uhdheight=2160`: demande UHD ciblee 4K
- `setmkt={market}`: marche (ex: `en-US`, `fr-FR`)
- `setlang=en`: langue de metadata

Note compatibilite:
- certains projets utilisent `mkt` (et parfois `cc`) au lieu de `setmkt`
- pour le MVP, on reste sur `setmkt` uniquement

## 5. Donnees a lire dans la reponse
Champs utiles dans `images[]`:
- `startdate` / `fullstartdate`: date publication
- `title`: titre
- `copyright`: credit/copyright
- `url`: chemin image relatif (souvent avec query)
- `urlbase`: base image (utile fallback)

Mapping minimal recommande:
- `id`: derive de `fullstartdate` + `urlbase`
- `title`: depuis `title` (fallback vide)
- `publishedAt`: depuis `startdate`
- `imageURL`: absolue, construite depuis `url` ou `urlbase`

## 6. Construction URL image
Strategie robuste:
1. Si `url` existe: construire `https://global.bing.com{url}`.
2. Sinon fallback: `https://global.bing.com{urlbase}_UHD.jpg`.

Puis telecharger et stocker localement dans le cache app.

## 7. Regles d usage dans l app
- Timeout court (ex: 10s) + retry limite (ex: 1 retry)
- Si echec Bing: fallback cache local puis bundle
- Dedupliquer sur `urlbase`/`id` pour eviter doublons
- Ne jamais bloquer l UI pendant fetch/download

## 8. Evolution prevue (post-MVP)
- Remplacer acces direct Bing par un gateway interne
- Cacher les N derniers wallpapers par market/lang
- Servir images via CDN
- Exposer un contrat stable pour le client (`/v1/wallpapers/...`)
