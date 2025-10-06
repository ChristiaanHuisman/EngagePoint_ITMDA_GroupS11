import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // <-- 1. Import Provider
import 'firebase_options.dart';
import 'models/settings_data.dart'; // <-- 2. Import your new model
import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. The KEY CHANGE: Wrap your app in a provider.
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
    // 4. We listen to the darkModeEnabled setting here to change the theme
    return Consumer<SettingsData>(
      builder: (context, settings, child) {
        return MaterialApp(
          title: 'EngagePoint',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: settings.darkModeEnabled ? Brightness.dark : Brightness.light,
            ),
            useMaterial3: true,
          ),
          home: const HomePage(),
        );
      },
    );
  }
}
