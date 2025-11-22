class ApiConstants {
  // For Flutter WEB - use the same port but with 127.0.0.1 instead of localhost
  static const String baseUrl = 'http://127.0.0.1:3000/api';
  
  // Alternative: Use your computer's IP address
  // static const String baseUrl = 'http://192.168.1.XXX:3000/api';
  
  static const String signupEndpoint = '/signup';
  static const String loginEndpoint = '/login';
}