@echo off
title Noisy - Traffic Generator
echo.
echo  ========================================
echo   NOISY - Traffic Noise Generator
echo  ========================================
echo.

:: Check Python
python --version >nul 2>&1
if errorlevel 1 (
    echo  [ERREUR] Python n'est pas installe.
    echo  Telecharge-le ici : https://www.python.org/downloads/
    echo.
    pause
    exit /b 1
)

:: Move to script directory
cd /d "%~dp0"

:: Create venv if missing
if not exist "venv" (
    echo  [1/3] Creation de l'environnement virtuel...
    python -m venv venv
    if errorlevel 1 (
        echo  [ERREUR] Impossible de creer le venv.
        pause
        exit /b 1
    )
)

:: Activate venv
call venv\Scripts\activate.bat

:: Install deps if needed
if not exist "venv\.deps_installed" (
    echo  [2/3] Installation des dependances...
    pip install -r requirements.txt --quiet
    if errorlevel 1 (
        echo  [ERREUR] Installation echouee.
        pause
        exit /b 1
    )
    echo ok > venv\.deps_installed
) else (
    echo  [2/3] Dependances deja installees.
)

echo  [3/3] Demarrage de Noisy + Dashboard...
echo.
echo  Dashboard : http://localhost:8080
echo  Appuie sur Ctrl+C pour arreter.
echo.

python noisy.py --dashboard %*

echo.
pause
