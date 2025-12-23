# Instructions de Build pour Windows

Ce guide explique comment créer un fichier .exe installable pour Windows avec toutes les dépendances nécessaires.

## Prérequis

1. **Flutter SDK** installé et configuré
   - Téléchargez depuis: https://flutter.dev/docs/get-started/install/windows
   - Vérifiez l'installation: `flutter doctor`

2. **Visual Studio** avec les outils de développement Windows
   - Visual Studio 2022 avec les composants:
     - Desktop development with C++
     - Windows 10/11 SDK

3. **Inno Setup** (optionnel, pour créer un installer)
   - Téléchargez depuis: https://jrsoftware.org/isdl.php
   - Version gratuite suffisante

## Étapes de Build

### Option 1: Build Automatique (Recommandé)

1. **Ouvrez PowerShell** en tant qu'administrateur dans le dossier du projet

2. **Exécutez le script de build:**
   ```powershell
   .\build_windows.ps1
   ```

3. **Attendez la fin du build** (peut prendre 5-15 minutes)

4. **L'application sera disponible dans:** `dist\coop_manager\coop_manager.exe`

### Option 2: Build Manuel

1. **Nettoyez le projet:**
   ```powershell
   flutter clean
   ```

2. **Récupérez les dépendances:**
   ```powershell
   flutter pub get
   ```

3. **Build pour Windows (Release):**
   ```powershell
   flutter build windows --release
   ```

4. **L'exécutable sera dans:** `build\windows\x64\runner\Release\coop_manager.exe`

## Création d'un Installer

### Avec Inno Setup (Recommandé)

1. **Installez Inno Setup** si ce n'est pas déjà fait

2. **Exécutez le script:**
   ```powershell
   .\create_installer.ps1
   ```

3. **L'installer sera créé dans:** `dist\CoopManager_Setup_v1.0.0.exe`

### Alternative: Package ZIP

Si Inno Setup n'est pas installé, le script créera automatiquement un fichier ZIP:
- `dist\CoopManager_v1.0.0_Windows.zip`

Les utilisateurs peuvent extraire ce fichier et exécuter `coop_manager.exe` directement.

## Distribution

### Fichiers à distribuer

**Option Installer (Recommandé):**
- `dist\CoopManager_Setup_v1.0.0.exe` - Installer complet

**Option Portable:**
- Tout le contenu du dossier `dist\coop_manager\` (exécutable + DLLs + données)

### Structure des fichiers distribués

```
coop_manager/
├── coop_manager.exe          (Exécutable principal)
├── *.dll                     (Bibliothèques natives requises)
├── data/                     (Assets Flutter)
│   ├── flutter_assets/
│   └── ...
└── README.txt                (Instructions pour l'utilisateur)
```

## Test de l'Application

1. **Sur votre machine:**
   - Exécutez `dist\coop_manager\coop_manager.exe`
   - Vérifiez que l'application démarre correctement

2. **Sur une machine de test (sans Flutter):**
   - Copiez tout le dossier `dist\coop_manager\` sur la machine de test
   - Exécutez `coop_manager.exe`
   - Vérifiez que toutes les fonctionnalités fonctionnent

## Dépannage

### Erreur: "Flutter n'est pas installé"
- Vérifiez que Flutter est dans le PATH
- Exécutez `flutter doctor` pour vérifier la configuration

### Erreur lors du build
- Vérifiez que Visual Studio est installé avec les composants C++
- Exécutez `flutter doctor` pour voir les problèmes

### L'application ne démarre pas sur une autre machine
- Vérifiez que tous les fichiers .dll sont présents
- Vérifiez que Windows 10/11 (64-bit) est installé
- Consultez les logs dans `%USERPROFILE%\Documents\coop_manager\logs\`

### DLL manquante
- Assurez-vous que tous les fichiers du dossier `build\windows\x64\runner\Release\` sont copiés
- Certaines DLLs peuvent nécessiter Visual C++ Redistributable (généralement déjà installé)

## Notes Importantes

- **Taille du package:** Environ 50-100 MB (selon les dépendances)
- **Architecture:** 64-bit uniquement
- **Système requis:** Windows 10 ou supérieur
- **Permissions:** L'application ne nécessite pas de droits administrateur pour fonctionner

## Support

Pour toute question ou problème, consultez:
- Documentation Flutter: https://flutter.dev/docs/deployment/windows
- Issues GitHub du projet

