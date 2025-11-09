import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // ADD THIS TEST METHOD
  Future<bool> testConnection() async {
  try {
    print('🔗 Testing connection to: http://127.0.0.1:5000/health');
    
    final response = await http.get(
      Uri.parse('http://127.0.0.1:5000/health'),
    ).timeout(const Duration(seconds: 5));
    
    print('🔗 Connection test response: ${response.statusCode}');
    print('🔗 Response body: ${response.body}');
    
    return response.statusCode == 200;
  } catch (e) {
    print('❌ Connection test failed: $e');
    return false;
  }
}

  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    try {
      print('🌐 Making API call to: ${ApiConstants.baseUrl}$endpoint');
      print('📦 Request data: $data');

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(data),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      final responseData = json.decode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('✅ API call successful');
        return responseData;
      } else {
        print('❌ API error: ${responseData['error']}');
        throw Exception(responseData['error'] ?? 'Request failed with status ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      print('❌ Network error: $e');
      throw Exception('Network error: Cannot connect to server. Is your Node.js server running?');
    } on Exception catch (e) {
      print('❌ General error: $e');
      throw Exception('Failed to connect: $e');
    }
  }

  Future<Map<String, dynamic>> signup(String email, String password, String name) async {
    return await post(ApiConstants.signupEndpoint, {
      'email': email,
      'password': password,
      'name': name,
    });
  }

  Future<Map<String, dynamic>> login(String idToken) async {
    return await post(ApiConstants.loginEndpoint, {
      'idToken': idToken,
    });
  }
}