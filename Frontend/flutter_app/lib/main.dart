import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/pages/customer_profile_page.dart';
import 'package:flutter_app/pages/login_page.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'models/post_model.dart';
import 'models/review_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pages/home_page.dart';
import 'pages/post_page.dart';
import 'pages/review_page.dart';
import 'providers/theme_provider.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';
import 'services/logging_service.dart';

// Global key for navigation from background notifications
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

// Handles navigation when a notification is tapped
Future<void> _handleNotificationNavigation(RemoteMessage message) async {
  // Short delay to ensure the app UI is ready
  await Future.delayed(const Duration(milliseconds: 500));

  final type = message.data['type'];
  debugPrint("Handling navigation for type: $type");

  // Log the notification open event
  final loggingService = LoggingService();
  final currentUser = FirebaseAuth.instance.currentUser; 
  loggingService.logAnalyticsEvent(
    eventName: 'notification_opened',
    parameters: {
      'type': type ?? 'unknown',
      'message_id': message.messageId ?? 'unknown',
      'user_id': currentUser?.uid ?? 'not_logged_in',
    },
  );

  final FirestoreService firestoreService = FirestoreService();

  // Navigate based on notification type
  if (type == 'new_post' || type == 'post_like') {
    final postId = message.data['postId'];
    if (postId != null) {
      final PostModel? post = await firestoreService.getPostById(postId);
      if (post != null && navigatorKey.currentContext != null) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (context) => PostPage(post: post)),
        );
      }
    }
  } else if (type == 'new_review' || type == 'review_response') {
    final reviewId = message.data['reviewId'];
    if (reviewId != null) {
      final ReviewModel? review =
          await firestoreService.getReviewById(reviewId);
      if (review != null && navigatorKey.currentContext != null) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (context) => ReviewPage(review: review)),
        );
      }
    }
  } else if (type == 'new_follower') {
    final followerId = message.data['followerId'];
    if (followerId != null && navigatorKey.currentContext != null) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
            builder: (context) => CustomerProfilePage(userId: followerId, scaffoldKey: GlobalKey<ScaffoldState>())),
      );
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  try {
    await NotificationService().initAndSaveToken();
  } catch (e) {
    debugPrint("Main: Notification Init failed (Ignored): $e");
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  try {
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _handleNotificationNavigation(message);
      }
    });
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationNavigation);
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground message received: ${message.notification?.title}');
    });
  } catch (e) {
     debugPrint("Main: Messaging listeners failed (Ignored): $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'EngagePoint',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            // Light Theme
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            // Dark Theme
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          themeMode: themeProvider.themeMode,
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasData) {
                return const HomePage();
              }
              return const LoginPage(); // Or SignUpPage, depending on flow
            },
          ),
        );
      },
    );
  }
}