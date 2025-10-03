import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/settings_data.dart';
import '../pages/login_page.dart';

class LoginApp extends StatelessWidget {
  const LoginApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SettingsData>(
      create: (BuildContext context) => SettingsData(),
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: "Login and Home Screen",
          theme: ThemeData(
            primarySwatch: Colors.deepPurple, // Change this to purple
            primaryColor: Colors.deepPurple, // Add this for more consistent purple
            colorScheme: ColorScheme.fromSwatch(
              primarySwatch: Colors.deepPurple, // Use purple MaterialColor
              brightness: Provider.of<SettingsData>(context).darkModeEnabled
                  ? Brightness.dark
                  : Brightness.light,
            ),
            visualDensity: VisualDensity.adaptivePlatformDensity,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.deepPurple, // Change AppBar color to purple
              foregroundColor: Colors.white,
              elevation: 4, // Optional: Add shadow
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent, // Change buttons to purple too
                foregroundColor: Colors.white,
              ),
            ),
          ),
          home: const LoginPage(),
        );
      },
    );
  }
}