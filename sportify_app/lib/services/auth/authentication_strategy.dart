import 'package:firebase_auth/firebase_auth.dart';

/// Abstract base class for authentication strategies
/// Applies Open/Closed Principle (OCP) - open for extension, closed for modification
/// Applies Polymorphism - different authentication methods can be used interchangeably
abstract class AuthenticationStrategy {
  /// Authenticate user using this strategy
  Future<User?> authenticate();

  /// Get the display name for this authentication method
  String get strategyName;
}

/// Email/Password authentication strategy
/// Applies Inheritance - extends AuthenticationStrategy
class EmailPasswordStrategy extends AuthenticationStrategy {
  final FirebaseAuth _auth;
  final String email;
  final String password;
  final String? userDisplayName;
  final bool isSignUp;

  EmailPasswordStrategy({
    required FirebaseAuth auth,
    required this.email,
    required this.password,
    this.userDisplayName,
    this.isSignUp = false,
  }) : _auth = auth;

  @override
  Future<User?> authenticate() async {
    if (isSignUp && userDisplayName != null) {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } else {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    }
  }

  @override
  String get strategyName => 'Email/Password';
}

