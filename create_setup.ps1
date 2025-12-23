# Script pour créer un installer Windows natif (sans Inno Setup)
# Utilise PowerShell et des outils Windows intégrés

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Création Installer Windows" -ForegroundColor Cyan
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

$version = "1.0.0"
$appName = "CoopManager"
$setupName = "CoopManager_Setup_v$version.exe"
$setupPath = "dist\$setupName"

Write-Host "Création de l'installer Windows..." -ForegroundColor Yellow
Write-Host ""

# Créer un script d'installation PowerShell
$installScript = @"
# Script d'installation pour Coop Manager
`$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Installation Coop Manager" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Demander le dossier d'installation
`$defaultPath = `"`$env:ProgramFiles\Coop Manager`"
Write-Host "Dossier d'installation par défaut: `$defaultPath" -ForegroundColor Yellow
`$installPath = Read-Host "Entrez le chemin d'installation (ou appuyez sur Entrée pour utiliser le défaut)"

if ([string]::IsNullOrWhiteSpace(`$installPath)) {
    `$installPath = `$defaultPath
}

# Créer le dossier d'installation
Write-Host ""
Write-Host "Création du dossier d'installation..." -ForegroundColor Yellow
if (-not (Test-Path `$installPath)) {
    New-Item -ItemType Directory -Path `$installPath -Force | Out-Null
}

# Extraire les fichiers
Write-Host "Installation des fichiers..." -ForegroundColor Yellow
`$sourcePath = `$PSScriptRoot
`$files = Get-ChildItem -Path `$sourcePath -Exclude "install.ps1", "*.ps1"

foreach (`$file in `$files) {
    `$destPath = Join-Path `$installPath `$file.Name
    if (`$file.PSIsContainer) {
        Copy-Item -Path `$file.FullName -Destination `$destPath -Recurse -Force
    } else {
        Copy-Item -Path `$file.FullName -Destination `$destPath -Force
    }
}

Write-Host "Fichiers installés avec succès!" -ForegroundColor Green
Write-Host ""

# Créer un raccourci sur le bureau
Write-Host "Création du raccourci sur le bureau..." -ForegroundColor Yellow
`$desktopPath = [Environment]::GetFolderPath("Desktop")
`$shortcutPath = Join-Path `$desktopPath "Coop Manager.lnk"
`$targetPath = Join-Path `$installPath "coop_manager.exe"

`$WScriptShell = New-Object -ComObject WScript.Shell
`$shortcut = `$WScriptShell.CreateShortcut(`$shortcutPath)
`$shortcut.TargetPath = `$targetPath
`$shortcut.WorkingDirectory = `$installPath
`$shortcut.Description = "Coop Manager - Application de gestion pour coopérative"
`$shortcut.Save()

Write-Host "Raccourci créé!" -ForegroundColor Green
Write-Host ""

# Créer un raccourci dans le menu Démarrer
Write-Host "Création du raccourci dans le menu Démarrer..." -ForegroundColor Yellow
`$startMenuPath = [Environment]::GetFolderPath("StartMenu")
`$programsPath = Join-Path `$startMenuPath "Programs"
if (-not (Test-Path `$programsPath)) {
    New-Item -ItemType Directory -Path `$programsPath -Force | Out-Null
}

`$startMenuShortcut = Join-Path `$programsPath "Coop Manager.lnk"
`$shortcut2 = `$WScriptShell.CreateShortcut(`$startMenuShortcut)
`$shortcut2.TargetPath = `$targetPath
`$shortcut2.WorkingDirectory = `$installPath
`$shortcut2.Description = "Coop Manager - Application de gestion pour coopérative"
`$shortcut2.Save()

Write-Host "Raccourci dans le menu Démarrer créé!" -ForegroundColor Green
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Installation terminée avec succès!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "L'application a été installée dans: `$installPath" -ForegroundColor Green
Write-Host ""
Write-Host "Vous pouvez maintenant lancer l'application depuis:" -ForegroundColor Yellow
Write-Host "  - Le raccourci sur le bureau" -ForegroundColor White
Write-Host "  - Le menu Démarrer > Coop Manager" -ForegroundColor White
Write-Host "  - Ou directement: `$targetPath" -ForegroundColor White
Write-Host ""
Read-Host "Appuyez sur Entrée pour terminer"
"@

# Créer un script d'auto-extraction
$extractScript = @"
# Auto-extracteur pour Coop Manager
`$ErrorActionPreference = "Stop"

# Obtenir le chemin du script
`$scriptPath = Split-Path -Parent `$MyInvocation.MyCommand.Path
`$tempDir = Join-Path `$env:TEMP "CoopManager_Install_`$([Guid]::NewGuid().ToString().Substring(0,8))"

Write-Host "Extraction des fichiers..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path `$tempDir -Force | Out-Null

# Les fichiers sont déjà extraits dans le même dossier que le script
`$sourceDir = `$scriptPath

# Exécuter le script d'installation
`$installScript = Join-Path `$sourceDir "install.ps1"
if (Test-Path `$installScript) {
    & powershell.exe -ExecutionPolicy Bypass -File `$installScript
} else {
    Write-Host "ERREUR: Script d'installation introuvable" -ForegroundColor Red
    Read-Host "Appuyez sur Entrée pour terminer"
    exit 1
}

# Nettoyer
Remove-Item -Path `$tempDir -Recurse -Force -ErrorAction SilentlyContinue
"@

# Créer un dossier temporaire pour l'installer
$tempInstallerDir = Join-Path $env:TEMP "CoopManager_Installer_$(Get-Random)"
New-Item -ItemType Directory -Path $tempInstallerDir -Force | Out-Null

# Copier tous les fichiers dans le dossier temporaire
Write-Host "Préparation des fichiers..." -ForegroundColor Yellow
Copy-Item -Path "$distDir\*" -Destination $tempInstallerDir -Recurse -Force

# Créer le script d'installation dans le dossier temporaire
Set-Content -Path "$tempInstallerDir\install.ps1" -Value $installScript

# Créer un script PowerShell séparé pour créer les raccourcis
$createShortcutsScript = @"
# Script pour créer les raccourcis
`$ErrorActionPreference = "Stop"

`$targetPath = `$args[0]
`$workingDir = `$args[1]

if (-not (Test-Path `$targetPath)) {
    Write-Host "ERREUR: L'executable n'existe pas: `$targetPath" -ForegroundColor Red
    exit 1
}

`$WshShell = New-Object -ComObject WScript.Shell

# Raccourci sur le bureau
`$desktopPath = [Environment]::GetFolderPath('Desktop')
`$desktopShortcut = Join-Path `$desktopPath 'Coop Manager.lnk'
`$shortcut1 = `$WshShell.CreateShortcut(`$desktopShortcut)
`$shortcut1.TargetPath = `$targetPath
`$shortcut1.WorkingDirectory = `$workingDir
`$shortcut1.Description = 'Coop Manager - Application de gestion pour cooperative'
`$shortcut1.IconLocation = `$targetPath
`$shortcut1.Save()
Write-Host "Raccourci sur le bureau cree" -ForegroundColor Green

# Raccourci dans le menu Demarrer
`$startMenuPath = [Environment]::GetFolderPath('StartMenu')
`$programsPath = Join-Path `$startMenuPath 'Programs'
if (-not (Test-Path `$programsPath)) {
    New-Item -ItemType Directory -Path `$programsPath -Force | Out-Null
}
`$startMenuShortcut = Join-Path `$programsPath 'Coop Manager.lnk'
`$shortcut2 = `$WshShell.CreateShortcut(`$startMenuShortcut)
`$shortcut2.TargetPath = `$targetPath
`$shortcut2.WorkingDirectory = `$workingDir
`$shortcut2.Description = 'Coop Manager - Application de gestion pour cooperative'
`$shortcut2.IconLocation = `$targetPath
`$shortcut2.Save()
Write-Host "Raccourci dans le menu Demarrer cree" -ForegroundColor Green
"@

Set-Content -Path "$tempInstallerDir\create_shortcuts.ps1" -Value $createShortcutsScript

# Créer un script PowerShell pour copier les fichiers
$copyFilesScript = @"
# Script pour copier les fichiers d'installation
param(
    [Parameter(Mandatory=`$true)]
    [string]`$source,
    [Parameter(Mandatory=`$true)]
    [string]`$dest
)

`$ErrorActionPreference = "Stop"

# Normaliser les chemins (supprimer les guillemets et espaces en fin)
`$source = `$source.Trim('"', ' ')
`$dest = `$dest.Trim('"', ' ')

if (-not (Test-Path `$source)) {
    Write-Host "ERREUR: Le dossier source n'existe pas: `$source" -ForegroundColor Red
    exit 1
}

Write-Host "Copie des fichiers depuis: `$source" -ForegroundColor Yellow
Write-Host "Vers: `$dest" -ForegroundColor Yellow
Write-Host ""

# Créer le dossier de destination s'il n'existe pas
if (-not (Test-Path `$dest)) {
    New-Item -ItemType Directory -Path `$dest -Force | Out-Null
}

# Liste des fichiers à exclure
`$exclude = @('INSTALLER.bat', 'install.ps1', 'extract.ps1', 'install.bat', 'README_INSTALL.txt', 'LISEZ_MOI.txt', 'create_shortcuts.ps1', 'copy_files.ps1')

# Copier les fichiers
`$files = Get-ChildItem -Path `$source -File | Where-Object { `$exclude -notcontains `$_.Name }
foreach (`$file in `$files) {
    try {
        Copy-Item -Path `$file.FullName -Destination `$dest -Force
        Write-Host "  Copie: `$(`$file.Name)" -ForegroundColor Gray
    } catch {
        Write-Host "  ERREUR lors de la copie de `$(`$file.Name): `$_" -ForegroundColor Red
    }
}

# Copier les dossiers (exclure les dossiers d'installation)
`$dirs = Get-ChildItem -Path `$source -Directory | Where-Object { `$_.Name -ne 'install' -and `$_.Name -ne 'extract' }
foreach (`$dir in `$dirs) {
    try {
        `$destDir = Join-Path `$dest `$dir.Name
        Copy-Item -Path `$dir.FullName -Destination `$destDir -Recurse -Force
        Write-Host "  Copie dossier: `$(`$dir.Name)" -ForegroundColor Gray
    } catch {
        Write-Host "  ERREUR lors de la copie du dossier `$(`$dir.Name): `$_" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Copie terminee" -ForegroundColor Green

# Vérifier que l'exécutable existe
`$exePath = Join-Path `$dest 'coop_manager.exe'
if (Test-Path `$exePath) {
    Write-Host "Executable verifie: OK" -ForegroundColor Green
} else {
    Write-Host "ERREUR: Executable non trouve apres copie!" -ForegroundColor Red
    Write-Host "Chemin attendu: `$exePath" -ForegroundColor Yellow
    exit 1
}
"@

Set-Content -Path "$tempInstallerDir\copy_files.ps1" -Value $copyFilesScript

# Créer le script d'auto-extraction
Set-Content -Path "$tempInstallerDir\extract.ps1" -Value $extractScript

# Créer un script batch qui lance l'installation
$batchScript = @"
@echo off
REM Installer Coop Manager
powershell.exe -ExecutionPolicy Bypass -File "%~dp0extract.ps1"
"@

Set-Content -Path "$tempInstallerDir\install.bat" -Value $batchScript

# Créer un fichier README pour l'installer
$readmeInstaller = @"
COOP MANAGER - INSTALLER

INSTRUCTIONS D'INSTALLATION:
============================

1. Double-cliquez sur install.bat
2. Suivez les instructions à l'écran
3. L'application sera installée et des raccourcis seront créés

L'application sera installée dans:
  %ProgramFiles%\Coop Manager

Des raccourcis seront créés sur:
  - Le bureau
  - Le menu Démarrer

VERSION: $version
"@

Set-Content -Path "$tempInstallerDir\README_INSTALL.txt" -Value $readmeInstaller

# Créer un package ZIP avec tous les fichiers
Write-Host "Création du package d'installation..." -ForegroundColor Yellow
$zipFile = "$env:TEMP\CoopManager_Installer_Temp.zip"
if (Test-Path $zipFile) {
    Remove-Item $zipFile -Force
}

Compress-Archive -Path "$tempInstallerDir\*" -DestinationPath $zipFile -Force

# Créer un script PowerShell qui extrait et installe
$finalInstallerScript = @"
# Installer Coop Manager v$version
`$ErrorActionPreference = "Stop"

# Obtenir le chemin du script
`$scriptPath = Split-Path -Parent `$MyInvocation.MyCommand.Path
`$tempDir = Join-Path `$env:TEMP "CoopManager_Extract_`$([Guid]::NewGuid().ToString().Substring(0,8))"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Installation Coop Manager" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Extraire le ZIP intégré
Write-Host "Extraction des fichiers..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path `$tempDir -Force | Out-Null

# Le ZIP est intégré dans ce script, on va le créer à partir des fichiers
# Pour simplifier, on va utiliser le dossier actuel
`$sourceDir = `$scriptPath

# Exécuter le script d'installation
`$installScript = Join-Path `$sourceDir "install.ps1"
if (Test-Path `$installScript) {
    & powershell.exe -ExecutionPolicy Bypass -File `$installScript
} else {
    Write-Host "ERREUR: Fichiers d'installation introuvables" -ForegroundColor Red
    Write-Host "Assurez-vous que tous les fichiers sont dans le même dossier que ce script." -ForegroundColor Yellow
    Read-Host "Appuyez sur Entrée pour terminer"
    exit 1
}

# Nettoyer
Remove-Item -Path `$tempDir -Recurse -Force -ErrorAction SilentlyContinue
"@

# Pour créer un vrai exécutable, on va créer un package auto-extracteur
# La meilleure approche est de créer un script batch qui lance PowerShell
$finalBatch = @"
@echo off
title Installation Coop Manager
echo ========================================
echo   Installation Coop Manager
echo ========================================
echo.
echo Extraction et installation en cours...
echo.

REM Changer vers le dossier du script
cd /d "%~dp0"

REM Lancer l'installation
powershell.exe -ExecutionPolicy Bypass -File "%~dp0install.ps1"

if errorlevel 1 (
    echo.
    echo ERREUR lors de l'installation
    pause
    exit /b 1
)
"@

# Créer un batch simple qui installe directement
$simpleInstaller = @"
@echo off
title Installation Coop Manager v$version
color 0B

echo.
echo ========================================
echo   Installation Coop Manager v$version
echo ========================================
echo.
echo Ce fichier va installer Coop Manager sur votre ordinateur.
echo.

REM Obtenir le chemin du script
set SCRIPT_DIR=%~dp0
set INSTALL_DIR=%ProgramFiles%\Coop Manager

echo Dossier d'installation: %INSTALL_DIR%
echo.
set /p CONFIRM="Continuer l'installation? (O/N): "
if /i not "%CONFIRM%"=="O" (
    echo Installation annulee.
    pause
    exit /b 0
)

echo.
echo Creation du dossier d'installation...
REM Demander les droits administrateur si nécessaire
if not exist "%INSTALL_DIR%" (
    mkdir "%INSTALL_DIR%" 2>nul
    if errorlevel 1 (
        echo ERREUR: Impossible de creer le dossier d'installation
        echo Veuillez executer ce script en tant qu'administrateur
        echo.
        echo Clic droit sur INSTALLER.bat ^> Executer en tant qu'administrateur
        pause
        exit /b 1
    )
)

echo Copie des fichiers...
REM Utiliser le script PowerShell inclus pour copier les fichiers
if exist "%~dp0copy_files.ps1" (
    REM Passer les arguments avec des guillemets pour gérer les espaces
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0copy_files.ps1" -source "%~dp0" -dest "%INSTALL_DIR%"
    if errorlevel 1 (
        echo ERREUR lors de la copie des fichiers
        pause
        exit /b 1
    )
) else (
    echo ERREUR: Script de copie introuvable
    echo Tentative de copie manuelle...
    copy /Y "%~dp0coop_manager.exe" "%INSTALL_DIR%\" >nul 2>&1
    if not exist "%INSTALL_DIR%\coop_manager.exe" (
        echo ERREUR: Impossible de copier l'executable
        pause
        exit /b 1
    )
)

echo.
echo Verification de l'installation...

REM Vérifier que l'exécutable existe
if not exist "%INSTALL_DIR%\coop_manager.exe" (
    echo.
    echo ERREUR: L'executable n'existe pas dans %INSTALL_DIR%
    echo.
    echo Fichiers trouves dans le dossier source:
    dir /b "%SCRIPT_DIR%" | findstr /v "INSTALLER install extract README LISEZ create_shortcuts"
    echo.
    echo Tentative de copie manuelle de l'executable...
    echo Chemin source: %SCRIPT_DIR%
    echo Chemin destination: %INSTALL_DIR%
    REM Utiliser PowerShell pour la copie (plus fiable avec les chemins)
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Copy-Item -Path '%SCRIPT_DIR%\coop_manager.exe' -Destination '%INSTALL_DIR%\coop_manager.exe' -Force; if (Test-Path '%INSTALL_DIR%\coop_manager.exe') { Write-Host 'Executable copie avec succes' -ForegroundColor Green } else { Write-Host 'ERREUR: Echec de la copie' -ForegroundColor Red; exit 1 }"
    if not exist "%INSTALL_DIR%\coop_manager.exe" (
        echo.
        echo ERREUR CRITIQUE: Impossible de copier l'executable
        echo.
        echo Veuillez verifier que:
        echo   1. Vous avez les droits administrateur
        echo   2. Le fichier coop_manager.exe existe dans: %SCRIPT_DIR%
        echo   3. Le dossier %INSTALL_DIR% peut etre cree/modifie
        echo.
        pause
        exit /b 1
    )
    echo Executable copie avec succes
)

echo Creation des raccourcis...

REM Créer les raccourcis en utilisant le script PowerShell inclus
if exist "%~dp0create_shortcuts.ps1" (
    powershell.exe -ExecutionPolicy Bypass -File "%~dp0create_shortcuts.ps1" "%INSTALL_DIR%\coop_manager.exe" "%INSTALL_DIR%"
) else (
    REM Méthode alternative si le script n'existe pas
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$WshShell = New-Object -ComObject WScript.Shell; $targetPath = '%INSTALL_DIR%\coop_manager.exe'; $workingDir = '%INSTALL_DIR%'; $desktopPath = [Environment]::GetFolderPath('Desktop'); $desktopShortcut = Join-Path $desktopPath 'Coop Manager.lnk'; $shortcut1 = $WshShell.CreateShortcut($desktopShortcut); $shortcut1.TargetPath = $targetPath; $shortcut1.WorkingDirectory = $workingDir; $shortcut1.Description = 'Coop Manager'; $shortcut1.IconLocation = $targetPath; $shortcut1.Save(); $startMenuPath = [Environment]::GetFolderPath('StartMenu'); $programsPath = Join-Path $startMenuPath 'Programs'; if (-not (Test-Path $programsPath)) { New-Item -ItemType Directory -Path $programsPath -Force | Out-Null }; $startMenuShortcut = Join-Path $programsPath 'Coop Manager.lnk'; $shortcut2 = $WshShell.CreateShortcut($startMenuShortcut); $shortcut2.TargetPath = $targetPath; $shortcut2.WorkingDirectory = $workingDir; $shortcut2.Description = 'Coop Manager'; $shortcut2.IconLocation = $targetPath; $shortcut2.Save(); Write-Host 'Raccourcis crees avec succes' -ForegroundColor Green"
)

REM Nettoyer
del exclude_files.txt >nul 2>&1

echo.
echo ========================================
echo   Installation terminee avec succes!
echo ========================================
echo.
echo L'application a ete installee dans: %INSTALL_DIR%
echo.
echo Vous pouvez maintenant lancer l'application depuis:
echo   - Le raccourci sur le bureau
echo   - Le menu Demarrer ^> Coop Manager
echo.
pause
"@

# Créer le batch installer final
Set-Content -Path "$tempInstallerDir\INSTALLER.bat" -Value $simpleInstaller -Encoding ASCII

# Copier tous les fichiers nécessaires
Write-Host "Finalisation de l'installer..." -ForegroundColor Yellow

# Créer le package final: un dossier avec tous les fichiers + un batch d'installation
$finalInstallerDir = "dist\CoopManager_Installer"
if (Test-Path $finalInstallerDir) {
    Remove-Item $finalInstallerDir -Recurse -Force
}
New-Item -ItemType Directory -Path $finalInstallerDir -Force | Out-Null

# Copier tous les fichiers de l'application
Copy-Item -Path "$distDir\*" -Destination $finalInstallerDir -Recurse -Force

# Copier le script d'installation
Set-Content -Path "$finalInstallerDir\INSTALLER.bat" -Value $simpleInstaller -Encoding ASCII

# Copier les scripts PowerShell
Copy-Item -Path "$tempInstallerDir\create_shortcuts.ps1" -Destination "$finalInstallerDir\create_shortcuts.ps1" -Force
Copy-Item -Path "$tempInstallerDir\copy_files.ps1" -Destination "$finalInstallerDir\copy_files.ps1" -Force

# Créer un README
Set-Content -Path "$finalInstallerDir\LISEZ_MOI.txt" -Value $readmeInstaller

# Créer un ZIP de l'installer
Write-Host "Création du package d'installation..." -ForegroundColor Yellow
$finalZip = "dist\CoopManager_Installer_v$version.zip"
if (Test-Path $finalZip) {
    Remove-Item $finalZip -Force
}
Compress-Archive -Path "$finalInstallerDir\*" -DestinationPath $finalZip -Force

# Nettoyer
Remove-Item -Path $tempInstallerDir -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path $zipFile -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Installer créé avec succès!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Deux options de distribution disponibles:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Dossier d'installation complet:" -ForegroundColor Cyan
Write-Host "   $finalInstallerDir" -ForegroundColor White
Write-Host "   → Distribuez ce dossier entier" -ForegroundColor Gray
Write-Host "   → Les utilisateurs exécutent INSTALLER.bat" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Package ZIP:" -ForegroundColor Cyan
Write-Host "   $finalZip" -ForegroundColor White
Write-Host "   → Distribuez ce fichier ZIP" -ForegroundColor Gray
Write-Host "   → Les utilisateurs extraient et exécutent INSTALLER.bat" -ForegroundColor Gray
Write-Host ""
Write-Host "INSTRUCTIONS POUR LES UTILISATEURS:" -ForegroundColor Yellow
Write-Host "1. Extraire le fichier ZIP (si distribué en ZIP)" -ForegroundColor White
Write-Host "2. Double-cliquer sur INSTALLER.bat" -ForegroundColor White
Write-Host "3. Suivre les instructions à l'écran" -ForegroundColor White
Write-Host "4. L'application sera installée dans Program Files" -ForegroundColor White
Write-Host "5. Des raccourcis seront créés sur le bureau et dans le menu Démarrer" -ForegroundColor White
Write-Host ""

