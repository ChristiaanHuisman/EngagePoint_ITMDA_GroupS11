import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light; 

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadThemePreference(); 
  }

  // Loads the saved theme preference from SharedPreferences.
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isDarkMode = prefs.getBool('darkModeEnabled') ?? false;
    _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    notifyListeners(); 
  }

  // Saves the theme preference and updates the theme mode.
  Future<void> toggleTheme(bool isDarkMode) async {
    _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    notifyListeners(); 

    // Save the preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkModeEnabled', isDarkMode);
  }
}