import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sportify_app/models/user_model.dart';
import 'package:sportify_app/services/interfaces/auth_service_interface.dart';
import 'package:sportify_app/repositories/user_repository.dart';

/// Authentication Service Implementation
/// Applies Single Responsibility Principle (SRP) - handles only authentication
/// Implements IAuthService interface - Dependency Inversion Principle (DIP)
class AuthService implements IAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserRepository _userRepository;
  GoogleSignIn? _googleSignIn;
  bool _googleSignInAvailable = true;

  /// Constructor with dependency injection
  /// Applies Dependency Inversion Principle (DIP)
  AuthService({UserRepository? userRepository})
      : _userRepository = userRepository ?? UserRepository();
  
  // Lazy initialization of GoogleSignIn to avoid errors if Client ID is not configured
  // We use a function instead of a getter to better handle errors
  GoogleSignIn? _getGoogleSignInInstance() {
    if (_googleSignIn == null && _googleSignInAvailable) {
      try {
        // Try to create GoogleSignIn - this may throw an assertion error on web
        // if Client ID is not configured
        _googleSignIn = GoogleSignIn();
        // Test if it's actually working by checking if we can access it
        // (this will fail silently if there's an issue)
      } on AssertionError catch (e) {
        // Catch assertion errors specifically (these happen in debug mode)
        print("Google Sign-In assertion error (Client ID not configured): $e");
        _googleSignInAvailable = false;
        _googleSignIn = null;
        return null;
      } catch (e) {
        print("Google Sign-In initialization failed: $e");
        _googleSignInAvailable = false;
        _googleSignIn = null;
        return null;
      }
    }
    return _googleSignIn;
  }

  /// Getter to expose the current user from Firebase Auth
  User? get currentUser => _auth.currentUser;

  /// Stream to listen for auth changes (e.g., login/logout)
  Stream<UserModel?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        return null;
      }
      // If the user is logged in, fetch their user document from Firestore
      return _getUserModel(firebaseUser.uid);
    });
  }

  /// Helper to get UserModel from Firestore
  /// Uses repository pattern for data access (Abstraction)
  Future<UserModel?> _getUserModel(String uid) async {
    try {
      return await _userRepository.getUserById(uid);
    } catch (e) {
      print("Error fetching user model: $e");
      return null;
    }
  }

  /// Sign Up with Email & Password
  Future<User?> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        UserModel newUser = UserModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email!,
          displayName: displayName,
          createdAt: DateTime.now(),
          role: UserRole.user,
        );

        // Use repository for data access (Abstraction)
        await _userRepository.createUser(newUser);

        return firebaseUser;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw e;
    } catch (e) {
      throw Exception("An unknown error occurred during sign up.");
    }
  }

  /// Sign In with Email & Password
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw e;
    } catch (e) {
      throw Exception("An unknown error occurred during sign in.");
    }
  }

  /// Sign In with Google
  Future<User?> signInWithGoogle() async {
    try {
      // Check if Google Sign-In is available
      final googleSignIn = _getGoogleSignInInstance();
      if (googleSignIn == null || !_googleSignInAvailable) {
        throw Exception(
          'Google Sign-In is not configured. Please add your Google Client ID to web/index.html. '
          'Replace YOUR_CLIENT_ID in web/index.html with your actual Google OAuth 2.0 Client ID.'
        );
      }
      
      // Try silent sign-in first, but catch errors (web can throw null bool errors)
      GoogleSignInAccount? googleUser;
      try {
        googleUser = await googleSignIn.signInSilently();
      } catch (e) {
        // Silent sign-in failed or threw an error (common on web)
        // This is expected behavior, continue to regular sign-in
        print("Silent sign-in not available: $e");
        googleUser = null;
      }
      
      // If silent sign-in fails, use regular sign-in
      if (googleUser == null) {
        try {
          googleUser = await googleSignIn.signIn();
        } catch (e) {
          print("Error during Google sign-in: $e");
          rethrow;
        }
        if (googleUser == null) {
          return null; // User cancelled
        }
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        if (userCredential.additionalUserInfo?.isNewUser == true) {
          UserModel newUser = UserModel(
            uid: firebaseUser.uid,
            email: firebaseUser.email!,
            displayName: firebaseUser.displayName,
            createdAt: DateTime.now(),
            role: UserRole.user,
          );
          // Use repository for data access (Abstraction)
          await _userRepository.createUser(newUser);
        }
        return firebaseUser;
      }
      return null;
    } catch (e) {
      print("Error signing in with Google: $e");
      rethrow; // Re-throw so the UI can show the error message
    }
  }

  /// Sign Out
  Future<void> signOut() async {
    try {
      final googleSignIn = _getGoogleSignInInstance();
      if (googleSignIn != null && _googleSignInAvailable) {
        try {
          if (await googleSignIn.isSignedIn()) {
            await googleSignIn.signOut();
          }
        } catch (e) {
          // Ignore Google sign out errors
          print("Error signing out from Google: $e");
        }
      }
      await _auth.signOut();
    } catch (e) {
      // Even if Google sign out fails, still sign out from Firebase
      await _auth.signOut();
    }
  }

  /// Forgot Password
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Change Password
  Future<void> changePassword(String newPassword) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
