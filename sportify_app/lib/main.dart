import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

// Interfaces (DIP)
import 'package:sportify_app/services/interfaces/auth_service_interface.dart';
import 'package:sportify_app/services/interfaces/firestore_service_interface.dart';
import 'package:sportify_app/services/interfaces/profile_service_interface.dart';

// Screens
import 'package:sportify_app/screens/auth_wrapper.dart';

// Configuration & Theme
import 'firebase_options.dart';
import 'package:sportify_app/theme/app_theme.dart';

// Concrete Service Imports (Required for provider list creation)
import 'package:sportify_app/services/auth_service.dart';
import 'package:sportify_app/services/firestore_service.dart';
import 'package:sportify_app/services/profile_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        // Dependencies registered as Interfaces (DIP)
        Provider<IAuthService>(
          create: (_) => AuthService(),
        ),
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        Provider<IFirestoreService>(
          create: (_) => FirestoreService(),
        ),
        Provider<FirestoreService>(
          create: (_) => FirestoreService(),
        ),
        Provider<IProfileService>(
          create: (_) => ProfileService(),
        ),
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

      // Applying the Theme (SRP)
      theme: AppTheme.stadiumNightTheme, // <-- ERROR HERE

      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
    );
  }
}
