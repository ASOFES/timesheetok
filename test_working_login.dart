import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('✅ Test avec les bons identifiants...');
  
  try {
    final response = await http.post(
      Uri.parse('https://timesheetapp.azurewebsites.net/api/Auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': 'test@test.com',
        'password': 'test123',
      }),
    ).timeout(Duration(seconds: 10));

    print('📡 Status: ${response.statusCode}');
    print('📄 Response complète:');
    print(response.body);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('\n🎉 SUCCÈS! Détails:');
      print('🔑 Token présent: ${data.containsKey('token')}');
      if (data.containsKey('token') && data['token'] != null) {
        final token = data['token'].toString();
        print('🔑 Token (début): ${token.length > 10 ? token.substring(0, 10) : token}...');
      }
      print('👤 User présent: ${data.containsKey('user')}');
      if (data.containsKey('user')) {
        print('👤 User data: ${data['user']}');
      }
    }
  } catch (e) {
    print('❌ Erreur: $e');
  }
}
