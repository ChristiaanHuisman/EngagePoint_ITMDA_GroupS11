import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
// core Flutter primitives
import 'package:flutter/foundation.dart';
// core FlutterFire dependency
import 'package:firebase_core/firebase_core.dart';

import 'services/auth_service.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'firebase_options.dart';
import 'models/settings_data.dart';

void main() async {
  // Ensure Flutter is ready before initializing Firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Wrap the entire app in a ChangeNotifierProvider to make SettingsData available globally
  runApp(
    ChangeNotifierProvider(
      create: (context) => SettingsData(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Use a Consumer to listen for changes in SettingsData and rebuild the theme
    return Consumer<SettingsData>(
      builder: (context, settings, child) {
        final systemUiOverlayStyle = SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,

          statusBarIconBrightness: settings.darkModeEnabled
              ? Brightness.light
              : Brightness.dark,
        );
        SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Engage Point',
          themeMode: settings.darkModeEnabled
              ? ThemeMode.dark
              : ThemeMode.light,

          // -- Light Theme Definition --
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.light,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.deepPurpleAccent,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),

          // -- Dark Theme Definition --
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.dark,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.deepPurpleAccent,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),

          home: const AuthWrapper(),
        );
      },
    );
  }
}

/// Wraps the app and shows LoginPage or HomePage based on the user's auth state.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const HomePage();
        }

        return const LoginPage();
      },
    );
  }
}
