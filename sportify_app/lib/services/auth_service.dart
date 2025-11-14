import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sportify_app/models/user_model.dart'; // Adjust path if needed

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Getter to expose the current user from Firebase Auth
  User? get currentUser => _auth.currentUser;

  /// Stream to listen for auth changes (e.g., login/logout)
  /// This is how your app will know if the user is logged in.
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
  Future<UserModel?> _getUserModel(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data()!);
      } else {
        return null; // Should not happen if signUp is correct
      }
    } catch (e) {
      print("Error fetching user model: $e"); // Use logger in production
      return null;
    }
  }

  /// Sign Up with Email & Password (UC-01 from your docs)
  /// This creates the user in Auth AND saves their data to Firestore.
  Future<User?> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      // 1. Create user in Firebase Auth
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        // 2. Create our UserModel
        UserModel newUser = UserModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email!,
          displayName: displayName,
          createdAt: DateTime.now(),
          role: UserRole.user, // Default role
        );

        // 3. Save the UserModel to Firestore
        await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .set(newUser.toJson());

        // --- THIS IS THE FIX ---
        // 4. Sign out the user to force them to log in
        await _auth.signOut();
        // --- END OF FIX ---

        return firebaseUser;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException: $e"); // Use logger
      // Handle errors (e.g., email-already-in-use)
      return null;
    } catch (e) {
      print("Error signing up: $e"); // Use logger
      return null;
    }
  }

  /// Sign In with Email & Password (UC-02)
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
      print("FirebaseAuthException: $e"); // Use logger
      // Handle errors (e.g., wrong-password, user-not-found)
      return null;
    } catch (e) {
      print("Error signing in: $e"); // Use logger
      return null;
    }
  }

  /// Sign In with Google (UC-01)
  Future<User?> signInWithGoogle() async {
    try {
      // 1. Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the flow
        return null;
      }

      // 2. Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 3. Create a new credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Sign in to Firebase with the credential
      UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        // 5. Check if this is a new user
        if (userCredential.additionalUserInfo?.isNewUser == true) {
          // This is the first time they logged in - create their Firestore doc
          UserModel newUser = UserModel(
            uid: firebaseUser.uid,
            email: firebaseUser.email!,
            displayName: firebaseUser.displayName,
            createdAt: DateTime.now(),
            role: UserRole.user,
          );
          await _firestore
              .collection('users')
              .doc(firebaseUser.uid)
              .set(newUser.toJson());
        }
        return firebaseUser;
      }
      return null;
    } catch (e) {
      print("Error signing in with Google: $e"); // Use logger
      return null;
    }
  }

  /// Sign Out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}