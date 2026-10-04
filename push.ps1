$ErrorActionPreference = "Continue"

Write-Host "1. Initialisation de Git..."
git init

Write-Host "2. Configuration de la branche main..."
git branch -M main

Write-Host "3. Configuration du remote GitHub..."
git remote remove origin 2>$null
git remote add origin https://github.com/DanK2436/jbf.git

Write-Host "4. Ajout des fichiers (README.md, .gitignore, et dossiers des sites web)..."
git add README.md .gitignore assets "JBF Admin" "JBF Client" "JBF Membre" "JBF Public"

Write-Host "5. Création du commit..."
git commit -m "first commit - sites web JBF (Public, Client, Membre, Admin)"

Write-Host "6. Envoi vers GitHub (git push -u origin main)..."
git push -u origin main
