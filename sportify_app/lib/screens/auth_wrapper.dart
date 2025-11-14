import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // <-- ADD THIS
import 'package:sportify_app/models/user_model.dart';
import 'package:sportify_app/services/auth_service.dart';
import 'package:sportify_app/screens/home_screen.dart';
import 'package:sportify_app/screens/login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // --- THIS IS THE FIX ---
    // Get the *shared* instance of AuthService from Provider
    final authService = Provider.of<AuthService>(context);
    // --- END OF FIX ---

    return StreamBuilder<UserModel?>(
      // Listen to the stream from that one shared instance
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData) {
          return const HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
