import 'package:firebase_auth/firebase_auth.dart';
import 'api_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ApiService _apiService = ApiService();

  // SIGN UP - Using Node.js backend
  Future<User?> signUp(String email, String password, String name) async {
    try {
      print('🚀 Calling Node.js signup API...');
      
      // 1. Call Node.js backend to create user in Firebase Auth + Firestore
      var apiResponse = await _apiService.signup(email, password, name);
      print('✅ Node.js response: $apiResponse');
      
      // 2. Sign in with Firebase Auth to get the user object
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('✅ Signed in with Firebase Auth: ${result.user!.uid}');
      return result.user;
    } catch (e) {
      print('❌ Signup error: $e');
      return null;
    }
  }

  // SIGN IN - Using Node.js backend
  Future<User?> signIn(String email, String password) async {
    try {
      print('🚀 Signing in with Firebase Auth...');
      
      // 1. Sign in with Firebase Auth
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('✅ Firebase signin successful: ${result.user!.uid}');
      
      // 2. Get ID token and verify with Node.js
      String? idToken = await result.user!.getIdToken();
      if (idToken != null) {
        var apiResponse = await _apiService.login(idToken);
        print('✅ Node.js login verification: $apiResponse');
      }
      
      return result.user;
    } catch (e) {
      print('❌ Signin error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}