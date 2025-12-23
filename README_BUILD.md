# 🚀 Guide Rapide de Build Windows

## Build Rapide (3 étapes)

### 1️⃣ Build de l'application
```powershell
.\build_windows.ps1
```

### 2️⃣ Créer l'installer (optionnel)
```powershell
.\create_installer.ps1
```

### 3️⃣ Distribuer
- **Avec installer:** `dist\CoopManager_Setup_v1.0.0.exe`
- **Sans installer:** Tout le dossier `dist\coop_manager\`

## ⚡ Build Ultra-Rapide (sans installer)

Si vous voulez juste tester rapidement:

```powershell
flutter build windows --release
```

L'exécutable sera dans: `build\windows\x64\runner\Release\coop_manager.exe`

## 📦 Ce qui est inclus dans le build

✅ Exécutable principal (`coop_manager.exe`)
✅ Toutes les DLLs natives requises
✅ Assets Flutter (polices, images, etc.)
✅ Base de données SQLite (créée au premier lancement)
✅ Configuration automatique

## 🎯 Pour tester sur une autre machine

1. Copiez tout le dossier `dist\coop_manager\`
2. Double-cliquez sur `coop_manager.exe`
3. C'est tout ! Aucune installation supplémentaire requise.

## ❓ Problèmes courants

**"Flutter n'est pas installé"**
→ Installez Flutter depuis https://flutter.dev

**"Erreur lors du build"**
→ Vérifiez que Visual Studio est installé avec C++

**"L'app ne démarre pas sur une autre machine"**
→ Assurez-vous que tous les fichiers .dll sont copiés

## 📝 Plus de détails

Consultez `BUILD_INSTRUCTIONS.md` pour plus d'informations.

