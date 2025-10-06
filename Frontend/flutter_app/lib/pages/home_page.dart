import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'login_page.dart'; // Make sure you have this page for navigation
import 'profile_page.dart';
import 'rewards_page.dart';
import 'settings_page.dart';

/// This widget is now the main entry point of your app after main.dart.
/// It wraps your entire app's logic and decides which page to show based on auth state.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _signOut() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. While waiting for the connection, show a loading indicator.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. The KEY CHANGE: If the snapshot has a user, show the main app.
        if (snapshot.hasData) {
          final user = snapshot.data!;
          // We can now pass this user object down to the main scaffold.
          return MainAppScaffold(user: user, onSignOut: _signOut);
        }

        // 3. If there is no user, show the LoginPage.
        return const LoginPage();
      },
    );
  }
}

/// This widget contains your full UI, including the AppBar and Drawer.
/// It is now a simple StatelessWidget that receives the user data.
class MainAppScaffold extends StatelessWidget {
  final User user;
  final Future<void> Function() onSignOut; // Callback for signing out

  const MainAppScaffold({
    super.key,
    required this.user,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              ),
              child: CircleAvatar(
                backgroundImage: NetworkImage(
                  user.photoURL ??
                      'https://static.vecteezy.com/system/resources/previews/009/292/244/non_2x/default-avatar-icon-of-social-media-user-vector.jpg',
                ),
                radius: 20,
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(user.displayName ?? 'User'),
              accountEmail: Text(user.email ?? 'No email'),
              currentAccountPicture: CircleAvatar(
                backgroundImage: NetworkImage(
                  user.photoURL ??
                      'https://static.vecteezy.com/system/resources/previews/009/292/244/non_2x/default-avatar-icon-of-social-media-user-vector.jpg',
                ),
              ),
              decoration: const BoxDecoration(color: Colors.deepPurpleAccent),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.leaderboard),
              title: const Text('Rewards & Progression'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RewardsAndProgressionPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context); // Closes the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                ); // Navigates to your page
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              // The onTap now calls the passed-in onSignOut function.
              // The StreamBuilder will automatically handle navigation.
              onTap: onSignOut,
            ),
          ],
        ),
      ),
      // This part now uses the Firestore StreamBuilder to get the role
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("User profile not found."));
          }
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final String role = userData['role'] ?? 'customer';

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Welcome ${user.displayName ?? 'User'}!",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Chip(
                  label: Text('Role: $role'),
                  backgroundColor: Colors.deepPurple.withOpacity(0.1),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
