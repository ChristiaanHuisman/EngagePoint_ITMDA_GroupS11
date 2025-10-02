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
            primarySwatch: Colors.blue,
            visualDensity: VisualDensity.adaptivePlatformDensity,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
            ),
            brightness: Provider.of<SettingsData>(context).darkModeEnabled
                ? Brightness.dark
                : Brightness.light,
          ),
          home: const LoginPage(),
        );
      },
    );
  }
}