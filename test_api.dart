import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🧪 Test de l\'API...');
  
  // Test 1: Vérifier la connectivité de base
  try {
    print('\n1️⃣ Test de connectivité...');
    final response = await http.get(
      Uri.parse('https://timesheetapp.azurewebsites.net/api'),
      headers: {'Content-Type': 'application/json'},
    ).timeout(Duration(seconds: 10));
    
    print('✅ API accessible - Status: ${response.statusCode}');
    final body = response.body;
    if (body.length > 200) {
      print('📄 Response: ${body.substring(0, 200)}...');
    } else {
      print('📄 Response: $body');
    }
  } catch (e) {
    print('❌ API non accessible: $e');
    return;
  }

  // Test 2: Test de login avec la bonne URL
  try {
    print('\n2️⃣ Test de login...');
    final loginResponse = await http.post(
      Uri.parse('https://timesheetapp.azurewebsites.net/api/Auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': 'admin@asofes.cd',
        'password': 'admin123',
      }),
    ).timeout(Duration(seconds: 10));

    print('📡 Login Status: ${loginResponse.statusCode}');
    print('📄 Login Response: ${loginResponse.body}');
    
    if (loginResponse.statusCode == 200) {
      final data = jsonDecode(loginResponse.body);
      print('✅ Login réussi!');
      print('🔑 Token reçu: ${data['token']?.substring(0, 20)}...');
      print('👤 User: ${data['user']}');
    } else {
      print('❌ Login échoué - Status: ${loginResponse.statusCode}');
    }
  } catch (e) {
    print('❌ Erreur login: $e');
  }

  // Test 3: Test avec auth/login (URL minuscule)
  try {
    print('\n3️⃣ Test avec URL minuscule...');
    final loginResponse2 = await http.post(
      Uri.parse('https://timesheetapp.azurewebsites.net/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': 'admin@asofes.cd',
        'password': 'admin123',
      }),
    ).timeout(Duration(seconds: 10));

    print('📡 Login Status (minuscule): ${loginResponse2.statusCode}');
    print('📄 Response: ${loginResponse2.body}');
  } catch (e) {
    print('❌ Erreur login minuscule: $e');
  }
}
