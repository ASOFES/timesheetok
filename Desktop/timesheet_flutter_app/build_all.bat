@echo off
echo ========================================
echo 🦋 TimeSheet Flutter - Build Script
echo ========================================
echo.

echo 📊 Analyse du code...
flutter analyze --no-fatal-infos
if %ERRORLEVEL% neq 0 (
    echo ❌ Erreurs détectées dans le code
    pause
    exit /b 1
)

echo.
echo 🌐 Compilation Web...
flutter build web
if %ERRORLEVEL% neq 0 (
    echo ❌ Erreur compilation Web
    pause
    exit /b 1
)

echo.
echo 📱 Compilation APK Android...
flutter build apk --release
if %ERRORLEVEL% neq 0 (
    echo ❌ Erreur compilation APK
    pause
    exit /b 1
)

echo.
echo ========================================
echo ✅ COMPILATION TERMINÉE AVEC SUCCÈS !
echo ========================================
echo.
echo 🌐 Web : build\web\
echo 📱 APK : build\app\outputs\flutter-apk\app-release.apk
echo.
echo 🚀 Pour tester en Web : flutter run -d web-server --web-port 8080
echo 📱 Pour installer APK : Transférez sur Android et installez
echo.
pause
