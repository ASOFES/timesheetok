# Intégration API Historique des Pointages

## Vue d'ensemble

L'application Flutter Timesheet a été mise à jour pour intégrer l'API de récupération de l'historique des pointages avec différents scopes temporels.

## API Endpoints

### Base URL
```
https://timesheetapp.azurewebsites.net/api
```

### Endpoint Historique
```
GET /Timesheet/Resume/UserId/{userId}/scope/{scope}
```

### Scopes disponibles
- **Scope 1** : Aujourd'hui
- **Scope 2** : Cette semaine  
- **Scope 3** : Ce mois (du 16 au 15 du mois suivant)

### Exemples d'URLs
- Pour TOTO (ID: 97) aujourd'hui : `https://timesheetapp.azurewebsites.net/api/Timesheet/Resume/UserId/97/scope/1`
- Pour TOTO cette semaine : `https://timesheetapp.azurewebsites.net/api/Timesheet/Resume/UserId/97/scope/2`
- Pour TOTO ce mois : `https://timesheetapp.azurewebsites.net/api/Timesheet/Resume/UserId/97/scope/3`

## Modifications apportées

### 1. ApiService (lib/services/api_service.dart)
- ✅ Ajout de la méthode `getTimesheetResume(userId, scope)`
- ✅ Gestion des erreurs HTTP et parsing JSON
- ✅ Helper `_getScopeLabel(scope)` pour les labels français

### 2. HistoryScreen (lib/screens/history_screen.dart)
- ✅ Intégration des 3 scopes (Aujourd'hui, Semaine, Mois)
- ✅ Chargement parallèle des données via `_loadAllResumes()`
- ✅ Affichage des statistiques en temps réel depuis l'API
- ✅ Indicateurs de chargement et badges "API"
- ✅ Section d'informations détaillées des resumes
- ✅ Fallback sur l'ancienne méthode si l'API échoue

### 3. Fonctionnalités
- 🔄 **Refresh automatique** : Les données se mettent à jour à chaque rafraîchissement
- 📊 **Statistiques en temps réel** : Compteurs mis à jour depuis l'API
- 🎯 **Gestion des erreurs** : Fallback gracieux si l'API est indisponible
- 📱 **Interface responsive** : Indicateurs visuels pour la source des données

## Structure des données attendues

L'API peut retourner les données dans différents formats :

### Format 1 : Objet avec compteurs
```json
{
  "totalCount": 5,
  "count": 5,
  "timesheets": [...]
}
```

### Format 2 : Liste directe
```json
[
  { "id": 1, "date": "2025-01-15", ... },
  { "id": 2, "date": "2025-01-14", ... }
]
```

## Utilisation dans l'application

1. **Connexion** : L'utilisateur se connecte avec son email/mot de passe
2. **Navigation** : Accès à l'écran "Historique" depuis le dashboard
3. **Chargement** : L'application appelle automatiquement les 3 scopes
4. **Affichage** : Les statistiques et détails sont affichés avec indicateurs "API"
5. **Refresh** : L'utilisateur peut rafraîchir manuellement les données

## Gestion des erreurs

- ✅ **API disponible** : Affichage des données réelles avec badge "API"
- ⚠️ **API indisponible** : Fallback sur les données locales
- 🔄 **Retry automatique** : Tentative de reconnexion au refresh
- 📱 **Feedback utilisateur** : Messages d'erreur clairs et actions suggérées

## Tests

Pour tester l'intégration :

1. **Lancer l'application** : `flutter run`
2. **Se connecter** avec un compte valide
3. **Naviguer vers Historique** 
4. **Vérifier** que les badges "API" apparaissent
5. **Tester le refresh** pour vérifier la mise à jour

## Prochaines étapes

- [ ] Ajouter la pagination pour les gros volumes de données
- [ ] Implémenter le cache local pour améliorer les performances
- [ ] Ajouter des filtres par date et type de pointage
- [ ] Intégrer les notifications push pour les nouveaux pointages
