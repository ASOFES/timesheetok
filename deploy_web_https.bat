@echo off
echo ========================================
echo    DEPLOY WEB HTTPS - TIMESHEET APP
echo ========================================
echo.

echo [1/4] Nettoyage du projet...
flutter clean
if %errorlevel% neq 0 (
    echo ❌ Erreur lors du nettoyage
    pause
    exit /b 1
)

echo [2/4] Récupération des dépendances...
flutter pub get
if %errorlevel% neq 0 (
    echo ❌ Erreur lors de la récupération des dépendances
    pause
    exit /b 1
)

echo [3/4] Construction de la version web...
flutter build web --release
if %errorlevel% neq 0 (
    echo ❌ Erreur lors de la construction web
    pause
    exit /b 1
)

echo [4/4] Démarrage du serveur HTTPS local...
echo.
echo 🚀 Application web accessible sur : https://localhost:8443
echo 🔐 Certificat SSL auto-signé sera créé automatiquement
echo 📱 La caméra devrait maintenant fonctionner !
echo.
echo ⚠️  IMPORTANT : Acceptez le certificat auto-signé dans votre navigateur
echo.

python serve_https.py

pause
