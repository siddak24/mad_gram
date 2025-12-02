import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; 

// Import the generated Firebase options
import 'firebase_options.dart'; 
// Import custom screens
import 'screens/auth/login_screen.dart'; 
import 'screens/main_layout.dart';
// 🌟 NEW: Import the custom theme 🌟
import 'core/utils/theme.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Start the application after widgets are initialized
  runApp(const MadGramApp());
}

class MadGramApp extends StatelessWidget {
  const MadGramApp({super.key});

  // Use a FutureBuilder to handle the asynchronous Firebase initialization
  Future<void> _initializeFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializeFirebase(),
      builder: (context, snapshot) {
        // --- 1. Handle Loading/Error States during Initialization ---
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(
              backgroundColor: Colors.black, 
              body: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          // Display the error message prominently for debugging
          return MaterialApp(
            home: Scaffold(
              backgroundColor: Colors.red,
              body: Center(
                child: Text(
                  'Firebase Init Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        // --- 2. Initialization Successful: Apply Theme and Check Auth ---
        return MaterialApp(
          title: 'MadGram',
          debugShowCheckedModeBanner: false,
          
          // 🌟 Apply the Custom Instagram-style Dark Theme 🌟
          theme: madGramTheme, 
          
          // Check the authentication state to show the correct starting screen
          home: StreamBuilder<User?>(
            // Listens to the Firebase Authentication state changes for persistence
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, authSnapshot) {
              if (authSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator(color: Colors.white)),
                );
              }
              
              // If the user is logged in
              if (authSnapshot.hasData && authSnapshot.data != null) {
                return const MainLayout(); // Show the main app screen
              }
              
              // If the user is NOT logged in or data is null
              return const LoginScreen(); 
            },
          ),
        );
      },
    );
  }
}