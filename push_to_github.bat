@echo off
setlocal
cd /d "%~dp0"

echo ============================================================
echo   JBF SERVICES - Synchronisation et Commit Automatique
echo ============================================================
echo.

echo [1/3] Indexation de tous les fichiers (git add -A)...
git add -A

set "MSG=Mise a jour automatique : %DATE% %TIME:~0,5% - Synchronisation JBF Web"
if not "%~1"=="" set "MSG=%~1"

echo.
echo [2/3] Creation du commit automatique...
echo Message : "%MSG%"
git commit -m "%MSG%"

echo.
echo [3/3] Envoi vers GitHub (git push origin main)...
git push origin main

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [INFO] Tentative de rebase automatique avec le depot distant...
    git pull --rebase origin main
    git push origin main
)

echo.
echo ============================================================
echo   Synchronisation terminee !
echo ============================================================
pause
