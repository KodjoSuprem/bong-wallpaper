# Setup Dev macOS Natif (Swift)

## 1. Prerequis
- macOS recent (idealement macOS 14+).
- Apple ID connecte a l App Store (pour Xcode).
- 20+ Go libres pour Xcode + simulateurs/outils.

## 2. Outils a installer
1. Installer Xcode depuis App Store.
2. Installer Command Line Tools:
   ```bash
   xcode-select --install
   ```
3. Verifier:
   ```bash
   xcodebuild -version
   swift --version
   ```

## 3. Creation du projet natif
Dans Xcode:
1. `File > New > Project > macOS > App`
2. Configuration:
- Product Name: `BongWallpaper`
- Interface: `SwiftUI`
- Language: `Swift`
- Use Core Data: `No` (MVP)
- Include Tests: `Yes`

## 4. Parametrage macOS menu bar app
### 4.1 Cible minimum
- Target `macOS 13+` (pour `MenuBarExtra` SwiftUI).

### 4.2 App agent (pas d icone Dock)
- Dans `Info.plist`, ajouter:
  - `Application is agent (UIElement) = YES`

### 4.3 Capacites (MVP)
- Pas de capability speciale obligatoire pour changer le wallpaper via API publique macOS.
- Network sortant utilise `URLSession`.

## 5. Structure recommandee
```text
BongWallpaper/
  App/
    BongWallpaperApp.swift
    StartupCoordinator.swift
  UI/
    MenuBar/
      MenuBarView.swift
      MenuBarViewModel.swift
  Domain/
    Models/Wallpaper.swift
    Protocols/
      WallpaperProvider.swift
      WallpaperApplying.swift
      Scheduler.swift
  Infrastructure/
    API/WallpaperAPIClient.swift
    Storage/WallpaperCache.swift
    Storage/PreferencesStore.swift
    System/DesktopWallpaperApplier.swift
    Scheduling/DailyRotationScheduler.swift
  Resources/
    BundledWallpapers/
  Tests/
    Unit/
    Integration/
```

## 6. Build et execution
### 6.1 Build local
```bash
xcodebuild -scheme BongWallpaper -configuration Debug build
```

### 6.2 Run
- Run depuis Xcode (`Cmd + R`).
- Verifier presence icone en menu bar.

### 6.3 Debug utile
- `Console.app` pour logs runtime.
- Breakpoints Xcode sur:
  - fetch API
  - ecriture cache
  - application wallpaper

## 7. Outils qualite (optionnel mais recommande)
### 7.1 SwiftLint
```bash
brew install swiftlint
```

### 7.2 SwiftFormat
```bash
brew install swiftformat
```

Ajouter scripts de build plus tard (post bootstrap).

## 8. Strategie de tests
- Unit tests sur:
  - selection `next/previous`
  - fallback offline
  - logique rotate daily
- Integration tests sur:
  - API mockee + cache
  - set wallpaper avec fake applier

## 9. Signature et distribution (plus tard)
- Pour dev local: signature automatique Xcode suffit.
- Pour distribution hors dev: notarization Apple sera necessaire (post-MVP).

## 10. Workflow quotidien recommande
1. Travailler en petites branches (`codex/...`).
2. Un module a la fois (UI, puis service, puis tests).
3. Toujours tester:
- lancement offline
- download online
- toggle rotate daily
