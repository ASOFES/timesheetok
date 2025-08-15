# 🔧 Guide de Test - Connexion Flutter

## ✅ **CORRECTIONS APPLIQUÉES**

J'ai corrigé les URLs de l'API Flutter pour utiliser **exactement la même stratégie** que votre version web :

### 🔄 **Changements effectués :**

1. **URL Login** : `/auth/login` → `/Auth/login` ✅
2. **URL Create Timesheet** : `/timesheets` → `/Timesheet` ✅  
3. **Structure du payload** : Alignée sur la version web ✅

---

## 🧪 **COMMENT TESTER**

### 🌐 **Version Web Flutter**
```bash
# Dans le dossier timesheet_flutter_app
flutter run -d web-server --web-port 8081
```
➡️ **Accès : http://localhost:8081**

### 📱 **APK Android**
L'APK précédent fonctionne encore, mais pour avoir les nouvelles corrections :
```bash
flutter build apk --release
```

---

## 🔐 **IDENTIFIANTS DE TEST**

Utilisez les **mêmes identifiants** que la version web :

**Email :** `admin@asofes.cd`
**Mot de passe :** `admin123`

*(Ces identifiants sont déjà pré-remplis dans l'écran de connexion)*

---

## 🔍 **URLS D'API UTILISÉES**

### ✅ **AVANT (ne marchait pas)**
- Login : `https://timesheetapp.azurewebsites.net/api/auth/login`
- Timesheet : `https://timesheetapp.azurewebsites.net/api/timesheets`

### ✅ **MAINTENANT (comme version web)**
- Login : `https://timesheetapp.azurewebsites.net/api/Auth/login`
- Timesheet : `https://timesheetapp.azurewebsites.net/api/Timesheet`

---

## 🎯 **PROCHAINS TESTS**

1. **🔐 Test de connexion** - Vérifier que les identifiants passent
2. **📱 Test de scan QR** - Vérifier le pointage
3. **📊 Test historique** - Vérifier l'affichage des données

---

## 🚨 **SI ÇA NE MARCHE TOUJOURS PAS**

**Vérifiez :**
1. Que l'API Azure est bien accessible
2. Que les identifiants sont corrects
3. Que le réseau/internet fonctionne
4. Comparez avec la version web qui marche

**Diagnostic :**
Les logs de connexion s'affichent dans la console du navigateur (F12) pour la version Web.

---

## 📝 **LOGS À SURVEILLER**

Dans la console Flutter, vous devriez voir :
```
🚀 Attempting login for: admin@asofes.cd
📡 Login response status: 200
✅ Login successful for: [nom utilisateur]
```

**Testez maintenant et dites-moi si la connexion passe ! 🎯**
