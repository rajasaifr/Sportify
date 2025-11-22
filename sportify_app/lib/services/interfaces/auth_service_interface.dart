import 'package:firebase_auth/firebase_auth.dart';
import 'package:sportify_app/models/user_model.dart';

/// Interface for authentication service
/// Applies Dependency Inversion Principle (DIP) - depend on abstractions
abstract class IAuthService {
  /// Getter to expose the current user from Firebase Auth
  User? get currentUser;

  /// Stream to listen for auth changes (e.g., login/logout)
  Stream<UserModel?> get authStateChanges;

  /// Sign Up with Email & Password
  Future<User?> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  });

  /// Sign In with Email & Password
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  });

  /// Sign In with Google
  Future<User?> signInWithGoogle();

  /// Sign Out
  Future<void> signOut();

  /// Forgot Password
  Future<void> sendPasswordResetEmail(String email);

  /// Change Password
  Future<void> changePassword(String newPassword);
}

