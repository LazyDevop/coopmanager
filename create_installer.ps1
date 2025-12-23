# Script pour créer un installer Windows avec Inno Setup
# Nécessite Inno Setup installé: https://jrsoftware.org/isdl.php

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Création de l'installer Windows" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Vérifier que le build existe
$distDir = "dist\coop_manager"
if (-not (Test-Path $distDir)) {
    Write-Host "ERREUR: Le dossier de distribution n'existe pas." -ForegroundColor Red
    Write-Host "Veuillez d'abord exécuter: .\build_windows.ps1" -ForegroundColor Yellow
    exit 1
}

# Vérifier que coop_manager.exe existe
if (-not (Test-Path "$distDir\coop_manager.exe")) {
    Write-Host "ERREUR: coop_manager.exe introuvable dans $distDir" -ForegroundColor Red
    exit 1
}

# Vérifier que Inno Setup est installé
$innoSetupPath = "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe"
if (-not (Test-Path $innoSetupPath)) {
    $innoSetupPath = "${env:ProgramFiles}\Inno Setup 6\ISCC.exe"
    if (-not (Test-Path $innoSetupPath)) {
        Write-Host "Inno Setup n'est pas installé." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Création d'un package ZIP portable à la place..." -ForegroundColor Cyan
        Write-Host ""
        
        # Créer le dossier dist s'il n'existe pas
        if (-not (Test-Path "dist")) {
            New-Item -ItemType Directory -Path "dist" -Force | Out-Null
        }
        
        # Créer un package ZIP à la place
        $zipFile = "dist\CoopManager_v1.0.0_Windows_Portable.zip"
        if (Test-Path $zipFile) {
            Remove-Item $zipFile -Force
        }
        
        Write-Host "Compression du package..." -ForegroundColor Yellow
        Compress-Archive -Path "$distDir\*" -DestinationPath $zipFile -Force
        
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "  Package ZIP créé avec succès!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Fichier créé: $zipFile" -ForegroundColor Green
        Write-Host ""
        Write-Host "INSTRUCTIONS POUR LES UTILISATEURS:" -ForegroundColor Yellow
        Write-Host "1. Extraire le fichier ZIP" -ForegroundColor White
        Write-Host "2. Double-cliquer sur coop_manager.exe" -ForegroundColor White
        Write-Host "3. Aucune installation requise!" -ForegroundColor White
        Write-Host ""
        Write-Host "Pour créer un installer .exe, installez Inno Setup:" -ForegroundColor Gray
        Write-Host "https://jrsoftware.org/isdl.php" -ForegroundColor Gray
        Write-Host ""
        exit 0
    }
}

Write-Host "Inno Setup détecté: $innoSetupPath" -ForegroundColor Green
Write-Host ""

# Compiler le script Inno Setup
Write-Host "Compilation de l'installer..." -ForegroundColor Yellow
& $innoSetupPath "installer_script.iss"

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Installer créé avec succès!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "L'installer est disponible dans: dist\CoopManager_Setup.exe" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "ERREUR lors de la création de l'installer" -ForegroundColor Red
    exit 1
}

