# Script de build pour Windows - Coop Manager
# Ce script génère un exécutable Windows avec toutes les dépendances

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Build Windows - Coop Manager" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Vérifier que Flutter est installé
Write-Host "Vérification de Flutter..." -ForegroundColor Yellow
$flutterVersion = flutter --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERREUR: Flutter n'est pas installé ou n'est pas dans le PATH" -ForegroundColor Red
    exit 1
}
Write-Host "Flutter détecté" -ForegroundColor Green
Write-Host ""

# Nettoyer les builds précédents
Write-Host "Nettoyage des builds précédents..." -ForegroundColor Yellow
flutter clean
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERREUR lors du nettoyage" -ForegroundColor Red
    exit 1
}
Write-Host "Nettoyage terminé" -ForegroundColor Green
Write-Host ""

# Récupérer les dépendances
Write-Host "Récupération des dépendances..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERREUR lors de la récupération des dépendances" -ForegroundColor Red
    exit 1
}
Write-Host "Dépendances récupérées" -ForegroundColor Green
Write-Host ""

# Build pour Windows (Release)
Write-Host "Build de l'application Windows (Release)..." -ForegroundColor Yellow
Write-Host "Cela peut prendre plusieurs minutes..." -ForegroundColor Yellow
flutter build windows --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERREUR lors du build" -ForegroundColor Red
    exit 1
}
Write-Host "Build terminé avec succès!" -ForegroundColor Green
Write-Host ""

# Créer le dossier de distribution
$distDir = "dist\coop_manager"
$releaseDir = "build\windows\x64\runner\Release"

Write-Host "Création du package de distribution..." -ForegroundColor Yellow

# Supprimer l'ancien dossier de distribution s'il existe
if (Test-Path $distDir) {
    Remove-Item -Recurse -Force $distDir
}

# Créer le dossier de distribution
New-Item -ItemType Directory -Path $distDir -Force | Out-Null

# Copier l'exécutable et les DLLs
Write-Host "Copie des fichiers exécutables..." -ForegroundColor Yellow
Copy-Item "$releaseDir\coop_manager.exe" "$distDir\" -Force
Copy-Item "$releaseDir\*.dll" "$distDir\" -Force

# Copier les données Flutter
Write-Host "Copie des données Flutter..." -ForegroundColor Yellow
if (Test-Path "$releaseDir\data") {
    Copy-Item "$releaseDir\data" "$distDir\data" -Recurse -Force
}

# Copier toutes les DLLs nécessaires depuis les sous-dossiers
Write-Host "Recherche des DLLs supplémentaires..." -ForegroundColor Yellow
Get-ChildItem -Path "$releaseDir" -Recurse -Filter "*.dll" | ForEach-Object {
    $destPath = Join-Path $distDir $_.Name
    if (-not (Test-Path $destPath)) {
        Copy-Item $_.FullName $distDir -Force
        Write-Host "  Copié: $($_.Name)" -ForegroundColor Gray
    }
}

# Vérifier les DLLs critiques
$criticalDlls = @("flutter_windows.dll", "dart.dll")
foreach ($dll in $criticalDlls) {
    if (-not (Test-Path "$distDir\$dll")) {
        Write-Host "ATTENTION: DLL critique manquante: $dll" -ForegroundColor Yellow
    }
}

# Créer un fichier README pour l'utilisateur
Write-Host "Création du fichier README..." -ForegroundColor Yellow
$readmeContent = @"
COOP MANAGER - Application de Gestion pour Coopérative

INSTRUCTIONS D'INSTALLATION:
============================

1. Double-cliquez sur 'coop_manager.exe' pour lancer l'application
2. L'application créera automatiquement sa base de données dans:
   %USERPROFILE%\Documents\coop_manager\

REQUIS SYSTÈME:
===============
- Windows 10 ou supérieur (64-bit)
- Aucune installation supplémentaire requise

DÉPANNAGE:
==========
Si l'application ne démarre pas:
1. Vérifiez que tous les fichiers .dll sont présents dans le dossier
2. Vérifiez les droits d'administration si nécessaire
3. Consultez les logs dans: %USERPROFILE%\Documents\coop_manager\logs\

VERSION: 1.0.0
DATE: $(Get-Date -Format "yyyy-MM-dd")
"@
Set-Content -Path "$distDir\README.txt" -Value $readmeContent

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Build terminé avec succès!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "L'application est disponible dans: $distDir" -ForegroundColor Green
Write-Host ""
Write-Host "Pour créer un installer, exécutez: .\create_installer.ps1" -ForegroundColor Yellow
Write-Host ""

