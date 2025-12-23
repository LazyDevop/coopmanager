# Script pour créer un package ZIP portable (sans installer)
# Alternative simple si Inno Setup n'est pas installé

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Création Package ZIP Portable" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Vérifier que le build existe
$distDir = "dist\coop_manager"
if (-not (Test-Path $distDir)) {
    Write-Host "ERREUR: Le dossier de distribution n'existe pas." -ForegroundColor Red
    Write-Host "Veuillez d'abord exécuter: .\build_windows.ps1" -ForegroundColor Yellow
    Write-Host "Ou double-cliquez sur: RUN_BUILD.bat" -ForegroundColor Yellow
    exit 1
}

# Vérifier que coop_manager.exe existe
if (-not (Test-Path "$distDir\coop_manager.exe")) {
    Write-Host "ERREUR: coop_manager.exe introuvable dans $distDir" -ForegroundColor Red
    exit 1
}

# Créer le dossier dist s'il n'existe pas
if (-not (Test-Path "dist")) {
    New-Item -ItemType Directory -Path "dist" -Force | Out-Null
}

# Créer un package ZIP
$version = "1.0.0"
$zipFile = "dist\CoopManager_v$version_Windows_Portable.zip"

if (Test-Path $zipFile) {
    Write-Host "Suppression de l'ancien package..." -ForegroundColor Yellow
    Remove-Item $zipFile -Force
}

Write-Host "Compression du package..." -ForegroundColor Yellow
Write-Host "Cela peut prendre quelques instants..." -ForegroundColor Gray
Write-Host ""

Compress-Archive -Path "$distDir\*" -DestinationPath $zipFile -Force

if (Test-Path $zipFile) {
    $fileSize = (Get-Item $zipFile).Length / 1MB
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Package ZIP créé avec succès!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Fichier: $zipFile" -ForegroundColor Green
    Write-Host "Taille: $([math]::Round($fileSize, 2)) MB" -ForegroundColor Gray
    Write-Host ""
    Write-Host "INSTRUCTIONS POUR LES UTILISATEURS:" -ForegroundColor Yellow
    Write-Host "1. Extraire le fichier ZIP dans un dossier" -ForegroundColor White
    Write-Host "2. Double-cliquer sur coop_manager.exe" -ForegroundColor White
    Write-Host "3. Aucune installation requise!" -ForegroundColor White
    Write-Host ""
    Write-Host "Le package contient:" -ForegroundColor Cyan
    Write-Host "  - coop_manager.exe (application)" -ForegroundColor Gray
    Write-Host "  - Toutes les DLLs nécessaires" -ForegroundColor Gray
    Write-Host "  - Assets Flutter" -ForegroundColor Gray
    Write-Host "  - README.txt (instructions)" -ForegroundColor Gray
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "ERREUR lors de la création du package ZIP" -ForegroundColor Red
    exit 1
}

