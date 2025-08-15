import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../models/timesheet.dart';

class ApiService {
  static const String baseUrl = 'https://timesheetapp.azurewebsites.net/api';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  
  // Mode de test local (pour contourner les problèmes CORS) - COPIÉ DE VOTRE APK
  static const bool _useLocalTest = false; // 🔧 DÉSACTIVÉ POUR UTILISER L'API RÉELLE

  // 🔧 GÉNÉRATION CODE UNIQUE - EXACTEMENT COMME LA VERSION WEB
  static String _generateUniqueCode() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'FLUTTER_$timestamp$random';
  }

  // Storage keys
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  // Authentication methods
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> saveUser(User user) async {
    await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
  }

  static Future<User?> getUser() async {
    final userJson = await _storage.read(key: _userKey);
    if (userJson != null) {
      return User.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  static Future<void> clearAuthData() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }

  static Future<bool> isAuthenticated() async {
    final token = await getToken();
    final user = await getUser();
    return token != null && user != null;
  }

  // HTTP headers with authentication
  static Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Login - MÉTHODE COPIÉE DE VOTRE APK QUI MARCHE
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('🚀 Attempting login for: $email');
      
      // Mode de test local pour contourner les problèmes CORS - COMME VOTRE APK
      if (_useLocalTest) {
        print('🧪 Mode de test local activé');
        
        // Simuler une connexion réussie pour TOTO - COMME VOTRE APK
        if (email.toLowerCase().contains('toto') || email.toLowerCase().contains('mulumba')) {
          print('🎯 Connexion simulée pour TOTO');
          
          // Créer un token de test
          final token = 'test_token_${DateTime.now().millisecondsSinceEpoch}';
          
          // Créer un utilisateur TOTO avec ID 97 - COMME VOTRE APK
          final user = User(
            id: 97,
            email: email,
            displayName: 'MULUMBA KABEYA TOTO',
            role: 'Employé',
          );
          
          await saveToken(token);
          await saveUser(user);
          
          print('🔑 Token de test créé: ${token.substring(0, 10)}...');
          print('👤 ID utilisateur: 97 (TOTO)');
          
          return {'success': true, 'user': user, 'token': token};
        }
        
        // Pour les autres utilisateurs, simuler une connexion basique - COMME VOTRE APK
        print('👤 Connexion simulée pour: $email');
        
        final token = 'test_token_${DateTime.now().millisecondsSinceEpoch}';
        final user = User(
          id: 1,
          email: email,
          displayName: email.split('@')[0],
          role: 'Employé',
        );
        
        await saveToken(token);
        await saveUser(user);
        
        return {'success': true, 'user': user, 'token': token};
      }
      
      // Mode normal (API réelle) - COMME VOTRE APK
      print('🌐 Tentative de connexion à l\'API réelle');
      final response = await http.post(
        Uri.parse('$baseUrl/Auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('📡 Login response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        
        // Forcer l'ID 97 pour TOTO - COMME VOTRE APK
        int userId = data['id'] ?? 1;
        print('🔍 ID reçu de l\'API: ${data['id']}');
        if (email.toLowerCase().contains('toto')) {
          userId = 97;
          print('🎯 Forçage de l\'ID utilisateur à 97 pour TOTO');
        }
        
        final user = User(
          id: userId,
          email: email,
          displayName: data['userName'] ?? email,
          role: 'Employé',
        );
        
        await saveToken(token);
        await saveUser(user);
        
        print('🔑 Token sauvegardé: ${token.substring(0, 10)}...');
        print('👤 ID utilisateur sauvegardé: $userId');
        
        return {'success': true, 'user': user, 'token': token};
      } else if (response.statusCode == 401) {
        print('❌ Identifiants incorrects: $email');
        throw Exception('Identifiants incorrects');
      } else {
        print('❌ Erreur de connexion: ${response.statusCode} - ${response.body}');
        throw Exception('Erreur de connexion: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Login error: $e');
      throw Exception('Erreur de connexion: ${e.toString()}');
    }
  }

  // Logout
  static Future<void> logout() async {
    print('🚪 Logging out...');
    await clearAuthData();
  }

  // Create Timesheet
  static Future<Map<String, dynamic>> createTimesheet({
    required int siteId,
    required int planningId,
    required int timesheetTypeId,
    required String qrData,
  }) async {
    try {
      final user = await getUser();
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // 🔧 GÉNÉRATION CODE UNIQUE - EXACTEMENT COMME LA VERSION WEB
      final uniqueCode = _generateUniqueCode();
      
      // 🔧 DETAILS COMPACTS - EXACTEMENT COMME LA VERSION WEB QUI MARCHE
      final details = {
        'uid': user.id, // ID de l'employé réel
        'un': user.displayName,
        'pid': planningId,
        'ts': DateTime.now().millisecondsSinceEpoch,
        'lat': 0.0, // Position par défaut
        'lng': 0.0
      };

      final payload = {
        'code': uniqueCode,
        'details': jsonEncode(details),
        'start': DateTime.now().toIso8601String(),
        'planningId': planningId,
        'timesheetTypeId': timesheetTypeId,
      };

      print('📤 Creating timesheet: $payload');

      // 🧪 MODE TEST LOCAL - EXACTEMENT COMME LA VERSION WEB QUI MARCHE
      if (_useLocalTest) {
        print('🧪 Mode test local - Simulation timesheet créé');
        // Simuler un délai réseau
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Simuler une réponse de succès
        final simulatedResult = {
          'id': DateTime.now().millisecondsSinceEpoch,
          'code': uniqueCode,
          'message': 'Timesheet créé avec succès (simulation)'
        };
        
        print('✅ Timesheet simulé créé: ${simulatedResult['id']}');
        return {'success': true, 'data': simulatedResult};
      }

      // MODE NORMAL (API RÉELLE) - EXACTEMENT COMME LA VERSION WEB
      final response = await http.post(
        Uri.parse('$baseUrl/Timesheet'),
        headers: await _getHeaders(),
        body: jsonEncode(payload),
      );

      print('📡 Timesheet response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('✅ Timesheet created successfully: ${data['id']}');
        return {'success': true, 'data': data};
      } else {
        print('❌ HTTP Error ${response.statusCode}: ${response.body}');
        try {
          final errorData = jsonDecode(response.body);
          final message = errorData['message'] ?? 'Failed to create timesheet';
          throw Exception('API Error ${response.statusCode}: $message');
        } catch (jsonError) {
          throw Exception('HTTP Error ${response.statusCode}: ${response.body}');
        }
      }
    } catch (e) {
      print('❌ Create timesheet error: $e');
      throw Exception('Failed to create timesheet: ${e.toString()}');
    }
  }

  // Get User Timesheets
  static Future<List<Timesheet>> getUserTimesheets(int userId) async {
    try {
      print('📊 Loading timesheets for user: $userId');

      final response = await http.get(
        Uri.parse('$baseUrl/timesheets/user/$userId'),
        headers: await _getHeaders(),
      );

      print('📡 Timesheets response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final timesheets = data.map((json) => Timesheet.fromJson(json)).toList();
        
        // Sort by creation date (newest first)
        timesheets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        print('📋 Loaded ${timesheets.length} timesheets');
        return timesheets;
      } else {
        final errorData = jsonDecode(response.body);
        final message = errorData['message'] ?? 'Failed to load timesheets';
        print('❌ Load timesheets failed: $message');
        throw Exception(message);
      }
    } catch (e) {
      print('❌ Load timesheets error: $e');
      throw Exception('Failed to load timesheets: ${e.toString()}');
    }
  }

  // Check if QR was already used today - MÉTHODE COPIÉE DE VOTRE VERSION WEB
  static Future<bool> checkQRUsedToday(String qrData, int userId) async {
    try {
      print('🔍 Vérification anti-doublon pour QR: $qrData');
      
      // Mode de test local - COMME VOTRE APK
      if (_useLocalTest) {
        print('🧪 Mode de test local - Vérification anti-doublon simulée');
        // Pour le test, on considère qu'il n'y a pas de doublon
        return false;
      }
      
      // Mode normal (API réelle) - COMME VOTRE APK
      final timesheets = await getUserTimesheets(userId);
      final today = DateTime.now();
      
      // Filtrer les pointages d'aujourd'hui
      final todayTimesheets = timesheets.where((ts) {
        return ts.createdAt.year == today.year &&
               ts.createdAt.month == today.month &&
               ts.createdAt.day == today.day;
      }).toList();

      print('📅 Pointages aujourd\'hui: ${todayTimesheets.length}');

      // Parser les données QR pour comparer les IDs - LOGIQUE DE VOTRE WEB
      try {
        final qrJson = jsonDecode(qrData);
        
        // Vérifier si ce QR (même site/planning) a déjà été utilisé aujourd'hui
        final siteId = qrJson['siteId'] ?? 1;
        final planningId = qrJson['planningId'] ?? qrJson['pid'] ?? 5;
        
        for (final timesheet in todayTimesheets) {
          try {
            if (timesheet.details != null && timesheet.details!.isNotEmpty) {
              final detailsJson = jsonDecode(timesheet.details!);
              final tsSiteId = detailsJson['siteId'] ?? 1;
              final tsPlanningId = detailsJson['pid'] ?? detailsJson['planningId'] ?? 5;
              
              if (tsSiteId == siteId && tsPlanningId == planningId) {
                print('🚫 QR déjà utilisé aujourd\'hui!');
                return true;
              }
            }
          } catch (e) {
            print('⚠️ Erreur parsing details timesheet: $e');
          }
        }
        
        print('✅ QR pas encore utilisé aujourd\'hui');
        return false;
        
      } catch (e) {
        print('⚠️ Erreur parsing QR JSON: $e');
        // Si on ne peut pas parser, on autorise (éviter de bloquer l'utilisateur)
        return false;
      }
    } catch (e) {
      print('❌ Erreur vérification anti-doublon: $e');
      // En cas d'erreur, autoriser le scan pour éviter de bloquer l'utilisateur
      return false;
    }
  }
}
