import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:sportify_app/services/auth_service.dart';
import 'package:sportify_app/services/firestore_service.dart';
import 'package:sportify_app/services/profile_service.dart'; // Added
import 'package:sportify_app/screens/auth_wrapper.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        // Provides the one, single instance of AuthService
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        // We'll also provide FirestoreService at the same time
        Provider<FirestoreService>(
          create: (_) => FirestoreService(),
        ),
        // Add ProfileService to the providers
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
        primarySwatch: Colors.blue,
        // A dark theme for a media app
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
