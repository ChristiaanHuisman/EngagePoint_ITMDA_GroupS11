import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'settings_page.dart';
import 'login_page.dart';


class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _signOut(BuildContext context) async {
    await AuthService().signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("No user is logged in.")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        // THE FIX: Use the main 'primary' color for a consistent deep purple.
        backgroundColor: Theme.of(context).colorScheme.primary,
        // To make the title and icons readable on the dark background
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 20),
              CircleAvatar(
                backgroundImage: NetworkImage(
                  user.photoURL ??
                      'https://static.vecteezy.com/system/resources/previews/009/292/244/non_2x/default-avatar-icon-of-social-media-user-vector.jpg',
                ),
                radius: 80,
              ),
              const SizedBox(height: 20),
              Text(
                user.displayName ?? 'Anonymous User',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                user.email ?? 'No email available',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              
              const SizedBox(height: 30),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text("Edit Profile"),
                onTap: () {
                  debugPrint('Edit Profile tapped');
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text("Settings"),
                onTap: () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) => const SettingsPage(),
                    ),
                  );
                },
              ),
              
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text("Notifications"),
                onTap: () {
                  debugPrint('Notifications tapped');
                },
              ),
              
            ],
          ),
        ),
      ),
    );
  }
}

