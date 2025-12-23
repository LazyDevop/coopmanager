@echo off
REM Script batch pour créer un installer Windows
REM Utilise des outils Windows natifs (pas besoin d'Inno Setup)

echo ========================================
echo   Creation Installer Windows
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
powershell.exe -ExecutionPolicy Bypass -File "create_setup.ps1"

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

