@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

cd /d "%~dp0"

echo ============================================================
echo   JBF SERVICES — Initialisation et Push Automatique
echo ============================================================
echo.

if not exist ".git" (
    echo Initialisation du dépôt Git...
    git init
    git branch -M main
    git remote remove origin 2>nul
    git remote add origin https://github.com/DanK2436/jbf.git
)

echo Indexation des fichiers...
git add -A

set DATETIME=%DATE% à %TIME:~0,5%
if not "%~1"=="" (
    set "COMMIT_MSG=%~1"
) else (
    set "COMMIT_MSG=Mise à jour automatique : %DATETIME% - OTP Brevo/Resend & plateforme JBF"
)

git commit -m "%COMMIT_MSG%" 2>nul

echo.
echo Envoi vers GitHub...
git push -u origin main

if %ERRORLEVEL% NEQ 0 (
    echo Tentative d'alignement avec le dépôt distant...
    git pull --rebase origin main
    git push -u origin main
)

echo.
echo ============================================================
echo   Terminé !
echo ============================================================
pause
