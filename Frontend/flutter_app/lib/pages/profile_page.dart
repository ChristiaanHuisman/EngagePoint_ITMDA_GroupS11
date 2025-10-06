import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <-- 1. Import Firebase Auth
import 'settings_page.dart';
import 'login_page.dart';


class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // 2. Get the current user from Firebase Auth
    final User? user = FirebaseAuth.instance.currentUser;

    // A safeguard in case this page is somehow reached without a user.
    if (user == null) {
      return const Scaffold(body: Center(child: Text("No user is logged in.")));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 20),
              CircleAvatar(
                // 3. Use the user's photoURL, with a fallback
                backgroundImage: NetworkImage(
                  user.photoURL ??
                      'https://static.vecteezy.com/system/resources/previews/009/292/244/non_2x/default-avatar-icon-of-social-media-user-vector.jpg',
                ),
                radius: 80,
              ),
              const SizedBox(height: 20),
              Text(
                // 4. Use the user's displayName, with a fallback
                user.displayName ?? 'Anonymous User',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                // 5. Use the user's email, with a fallback
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
              const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Logout', style: TextStyle(color: Colors.red)),
                   onTap: () {
                  Navigator.pushReplacement<void, void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) => const LoginPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
