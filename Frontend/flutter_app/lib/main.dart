import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; 
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:firebase_analytics/firebase_analytics.dart';


import 'services/auth_service.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'firebase_options.dart';
import 'models/settings_data.dart';
import 'pages/home_page.dart';
import 'services/notification_service.dart';

void main() async {
  // This is required to ensure that plugin services are initialized before running the app
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService().initAndSaveToken();
  
  // Request permission from the user to receive push notifications.
  
  try {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');
  } catch (e) {
    debugPrint("Error requesting notification permission: $e");
  }
  

  runApp(
    ChangeNotifierProvider(
      create: (context) => SettingsData(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {

  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;//allows calls of the analytics.logEvent method.

  MyApp({super.key});
  

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsData>(
      builder: (context, settings, child) {
        return MaterialApp(
          title: 'Engage Point',
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

