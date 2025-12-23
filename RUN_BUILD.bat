@echo off
REM Script batch pour exécuter le build Windows
REM Ce script contourne les problèmes de politique PowerShell

echo ========================================
echo   Build Windows - Coop Manager
echo ========================================
echo.

REM Vérifier si PowerShell est disponible
where powershell >nul 2>&1
if errorlevel 1 (
    echo ERREUR: PowerShell n'est pas installe
    pause
    exit /b 1
)

echo Execution du script PowerShell...
echo.

REM Exécuter le script PowerShell en contournant la politique d'exécution
powershell.exe -ExecutionPolicy Bypass -File "build_windows.ps1"

if errorlevel 1 (
    echo.
    echo ERREUR lors de l'execution du script
    pause
    exit /b 1
)

echo.
echo ========================================
echo   Termine!
echo ========================================
pause

