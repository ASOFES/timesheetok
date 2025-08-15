import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🔐 Test de différents identifiants...');
  
  // Liste des identifiants à tester
  final credentialsList = [
    {'email': 'admin@asofes.cd', 'password': 'admin123'},
    {'email': 'admin', 'password': 'admin123'},
    {'email': 'admin@example.com', 'password': 'admin123'},
    {'email': 'admin@asofes.cd', 'password': 'password'},
    {'email': 'admin@asofes.cd', 'password': 'admin'},
    {'email': 'test@test.com', 'password': 'test123'},
  ];

  for (int i = 0; i < credentialsList.length; i++) {
    final creds = credentialsList[i];
    print('\n${i + 1}️⃣ Test: ${creds['email']} / ${creds['password']}');
    
    try {
      final response = await http.post(
        Uri.parse('https://timesheetapp.azurewebsites.net/api/Auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(creds),
      ).timeout(Duration(seconds: 10));

      print('📡 Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ SUCCÈS! Token: ${data['token']?.substring(0, 20)}...');
        print('👤 User: ${data['user']}');
        break;
      } else if (response.statusCode == 401) {
        print('❌ Unauthorized (identifiants incorrects)');
      } else {
        print('⚠️ Autre erreur: ${response.body}');
      }
    } catch (e) {
      print('❌ Erreur: $e');
    }
  }
  
  print('\n🔍 Si aucun ne marche, vérifiez les identifiants dans la version web qui fonctionne!');
}
