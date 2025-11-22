import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sportify_app/models/user_model.dart';
import 'package:sportify_app/services/auth_service.dart';
import 'package:sportify_app/screens/home_screen.dart';
import 'package:sportify_app/screens/login_screen.dart';
import 'package:sportify_app/utils/logger.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return StreamBuilder<User?>(
      // Use authService's auth stream, not _auth directly
      stream: authService.authStateChanges.asyncMap((userModel) => 
          userModel != null ? FirebaseAuth.instance.currentUser : null),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final user = snapshot.data;
        
        if (user != null) {
          // User is authenticated in Firebase Auth
          // Ensure they have a Firestore document
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _ensureUserDocument(context, user);
          });
          
          return const HomeScreen();
        } else {
          // No user authenticated
          return const LoginScreen();
        }
      },
    );
  }

  void _ensureUserDocument(BuildContext context, User firebaseUser) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .get();
      
      if (!userDoc.exists) {
        Logger.info("Creating missing user document for: ${firebaseUser.uid}", tag: 'AuthWrapper');
        
        UserModel newUser = UserModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email!,
          displayName: firebaseUser.displayName ?? 'User',
          createdAt: DateTime.now(),
          role: UserRole.user,
          bio: '',
          favoriteTeams: [],
        );
        
        await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .set(newUser.toJson());
            
        Logger.info("User document created successfully", tag: 'AuthWrapper');
      }
    } catch (e) {
      Logger.error("Error ensuring user document", error: e, tag: 'AuthWrapper');
    }
  }
}