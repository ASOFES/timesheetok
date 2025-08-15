@echo off
echo ========================================
echo    DEPLOY NETLIFY - TIMESHEET APP
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

echo [4/4] Déploiement sur Netlify...
echo.
echo 🚀 Votre application web est prête pour le déploiement !
echo.
echo 📋 Étapes pour déployer sur Netlify :
echo.
echo 1️⃣  Allez sur : https://app.netlify.com/
echo 2️⃣  Connectez-vous ou créez un compte
echo 3️⃣  Cliquez sur "New site from Git"
echo 4️⃣  Choisissez votre repository GitHub : Ckiwabonga/timesheetToto
echo 5️⃣  Configurez les paramètres :
echo     - Build command : flutter build web --release
echo     - Publish directory : build/web
echo 6️⃣  Cliquez sur "Deploy site"
echo.
echo 🌐 Votre site sera accessible avec HTTPS automatique !
echo 📱 La caméra fonctionnera parfaitement !
echo.
echo 💡 Alternative : Glissez-déposez le dossier build/web sur Netlify
echo.
pause
