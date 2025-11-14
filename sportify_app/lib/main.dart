import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart'; // <-- ADD THIS
import 'package:sportify_app/services/auth_service.dart'; // <-- ADD THIS
import 'package:sportify_app/services/firestore_service.dart'; // <-- ADD THIS
import 'package:sportify_app/screens/auth_wrapper.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    // --- THIS IS THE NEW WIDGET ---
    // It provides our services to the entire app
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
      ],
      child: const MyApp(), // Your original app
    ),
    // --- END OF NEW WIDGET ---
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
