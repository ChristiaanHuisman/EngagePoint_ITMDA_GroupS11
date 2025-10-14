import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../models/settings_data.dart';
import '../pages/login_page.dart';
import '../pages/home_page.dart';

class LoginApp extends StatelessWidget {
  const LoginApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SettingsData>(
      create: (_) => SettingsData(),
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: "Engage Point",
          theme: ThemeData(
            primarySwatch: Colors.deepPurple,
            colorScheme: ColorScheme.fromSwatch(
              primarySwatch: Colors.deepPurple,
              brightness: Provider.of<SettingsData>(context).darkModeEnabled
                  ? Brightness.dark
                  : Brightness.light,
            ),
          ),
          // StreamBuilder automatically shows Home if logged in
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              return snapshot.hasData ? const HomePage() : const LoginPage();
            },
          ),
        );
      },
    );
  }
}
