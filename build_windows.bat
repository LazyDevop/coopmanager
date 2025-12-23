@echo off
REM Script batch pour build Windows (alternative au PowerShell)
REM Utilisez build_windows.ps1 de préférence

echo ========================================
echo   Build Windows - Coop Manager
echo ========================================
echo.

echo Verification de Flutter...
flutter --version
if errorlevel 1 (
    echo ERREUR: Flutter n'est pas installe ou n'est pas dans le PATH
    pause
    exit /b 1
)
echo.

echo Nettoyage des builds precedents...
flutter clean
if errorlevel 1 (
    echo ERREUR lors du nettoyage
    pause
    exit /b 1
)
echo.

echo Recuperation des dependances...
flutter pub get
if errorlevel 1 (
    echo ERREUR lors de la recuperation des dependances
    pause
    exit /b 1
)
echo.

echo Build de l'application Windows (Release)...
echo Cela peut prendre plusieurs minutes...
flutter build windows --release
if errorlevel 1 (
    echo ERREUR lors du build
    pause
    exit /b 1
)
echo.

echo ========================================
echo   Build termine avec succes!
echo ========================================
echo.
echo L'application est disponible dans: build\windows\x64\runner\Release
echo.

pause

