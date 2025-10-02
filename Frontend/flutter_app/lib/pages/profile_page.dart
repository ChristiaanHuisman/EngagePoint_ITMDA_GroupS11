import 'package:flutter/material.dart';
import 'login_page.dart';
import 'settings_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 20),
              const CircleAvatar(
                backgroundImage: NetworkImage(
                  'https://static.vecteezy.com/system/resources/previews/009/292/244/non_2x/default-avatar-icon-of-social-media-user-vector.jpg',
                ),
                radius: 80,
              ),
              const SizedBox(height: 20),
              Text(
                "John Doe",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                "john.doe@example.com",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    "1,234",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    "Following",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[700]),
                  ),
                ],
              ),
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
                  debugPrint('Settings tapped');
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
                title: const Text(
                  "Logout",
                  style: TextStyle(color: Colors.red),
                ),
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