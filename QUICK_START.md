# 🚀 Démarrage Rapide - Build Windows

## ⚡ Méthode la plus simple

**Double-cliquez simplement sur:** `RUN_BUILD.bat`

Ce fichier exécutera automatiquement le build sans problème de politique PowerShell.

## 🔧 Méthodes alternatives

### Option 1: PowerShell avec politique bypass

Ouvrez PowerShell et exécutez:

```powershell
powershell.exe -ExecutionPolicy Bypass -File "build_windows.ps1"
```

### Option 2: Changer la politique d'exécution (une seule fois)

Ouvrez PowerShell **en tant qu'administrateur** et exécutez:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Ensuite, vous pourrez exécuter directement:
```powershell
.\build_windows.ps1
```

### Option 3: Utiliser le fichier .bat

Double-cliquez sur `build_windows.bat` (build basique sans packaging)

## 📝 Erreurs courantes

### "Le terme n'est pas reconnu"
- **Solution:** Utilisez `RUN_BUILD.bat` ou ajoutez `.ps1` à la fin: `.\build_windows.ps1`

### "Cannot run script because execution policy"
- **Solution:** Utilisez `RUN_BUILD.bat` ou exécutez avec `-ExecutionPolicy Bypass`

### "Flutter n'est pas installé"
- **Solution:** Installez Flutter depuis https://flutter.dev

## ✅ Après le build

L'application sera disponible dans:
- **Dossier portable:** `dist\coop_manager\coop_manager.exe`

## 📦 Créer un package pour distribution

### Option 1: Installer Windows (Recommandé - Professionnel)
**Double-cliquez sur:** `RUN_CREATE_SETUP.bat`

Cela créera un installer complet avec:
- Installation dans Program Files
- Création de raccourcis (bureau + menu Démarrer)
- Interface d'installation professionnelle

**Résultat:** `dist\CoopManager_Installer_v1.0.0.zip`

### Option 2: Package ZIP Portable (Simple)
**Double-cliquez sur:** `RUN_CREATE_ZIP.bat`

Cela créera: `dist\CoopManager_v1.0.0_Windows_Portable.zip`
- Application portable (pas d'installation)
- Les utilisateurs extraient et exécutent directement

### Option 3: Installer avec Inno Setup (Si installé)
**Double-cliquez sur:** `RUN_INSTALLER.bat`

Crée un installer .exe professionnel (nécessite Inno Setup)

## 🎯 Distribution

**Pour distribuer l'application:**

1. **Package ZIP (le plus simple):**
   - Utilisez `RUN_CREATE_ZIP.bat`
   - Distribuez le fichier ZIP
   - Les utilisateurs extraient et exécutent `coop_manager.exe`

2. **Installer Windows:**
   - Utilisez `RUN_INSTALLER.bat` (nécessite Inno Setup)
   - Distribuez le fichier `.exe` d'installation
   - Les utilisateurs exécutent l'installer

