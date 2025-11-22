import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

// Services
import 'package:sportify_app/services/auth_service.dart';
import 'package:sportify_app/services/firestore_service.dart';
import 'package:sportify_app/services/profile_service.dart';
// Interfaces - Dependency Inversion Principle (DIP)
import 'package:sportify_app/services/interfaces/auth_service_interface.dart';
import 'package:sportify_app/services/interfaces/firestore_service_interface.dart';
import 'package:sportify_app/services/interfaces/profile_service_interface.dart';

// Screens
import 'package:sportify_app/screens/auth_wrapper.dart';
import 'package:sportify_app/utils/logger.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        // Dependency Inversion Principle (DIP) - depend on interfaces, not concrete classes
        // Services are provided as interfaces but implemented by concrete classes
        Provider<IAuthService>(
          create: (_) {
            try {
              return AuthService();
            } catch (e) {
              // If AuthService creation fails, still create it
              // The lazy initialization will handle Google Sign-In errors
              Logger.warning("AuthService creation had issues", error: e, tag: 'AuthService');
              return AuthService();
            }
          },
        ),
        // Provide concrete implementation for backward compatibility
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        Provider<IFirestoreService>(
          create: (_) => FirestoreService(),
        ),
        // Provide concrete implementation for backward compatibility
        Provider<FirestoreService>(
          create: (_) => FirestoreService(),
        ),
        Provider<IProfileService>(
          create: (_) => ProfileService(),
        ),
        // Provide concrete implementation for backward compatibility
        Provider<ProfileService>(
          create: (_) => ProfileService(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sportify',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1F1F1F),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
    );
  }
}