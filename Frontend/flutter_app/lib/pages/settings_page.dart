import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/pages/notification_settings_page.dart';
import '../models/user_model.dart';
import '../providers/theme_provider.dart';
import '../services/firestore_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: SafeArea(
        child: StreamBuilder<UserModel?>(
          stream: firestoreService.getUserStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final user = snapshot.data;
            if (user == null) {
              return const Center(child: Text("Could not load user settings."));
            }

            final prefs = user.notificationPreferences;
            final bool receiveNotificationsEnabled = prefs.onNewPost;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Notifications Section
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      "Notifications",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  SwitchListTile(
                    title: const Text("Receive Notifications"),
                    subtitle:
                        const Text("Enable/disable detailed settings below"),
                    value: receiveNotificationsEnabled,
                    onChanged: (bool value) {
                      // Update preferences in firestore
                      firestoreService.updateNotificationPreference(
                          'onNewPost', value);
                    },
                    activeThumbColor: Theme.of(context).colorScheme.primary,
                  ),
                  ListTile(
                    title: const Text("Advanced Notification Settings"),
                    subtitle:
                        const Text("Manage post, review, and quiet hours"),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      color: receiveNotificationsEnabled
                          ? Colors.grey.shade700
                          : Colors.grey.shade400,
                    ),
                    enabled: receiveNotificationsEnabled,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const NotificationSettingsPage()),
                      );
                    },
                  ),

                  const Divider(height: 32),

                  // Privacy Section
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      "Privacy",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),

                  CheckboxListTile(
                    title: const Text("Private Profile"),
                    subtitle: const Text(
                        "Hide your activity (e.g., reviews) from others"),
                    value: user.isPrivate,
                    onChanged: (bool? value) {
                      if (value != null) {
                        firestoreService.updateUserPrivacy(value);
                      }
                    },
                  ),

                  const Divider(height: 32),

                  //App Section
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      "App",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  SwitchListTile(
                    title: const Text("Dark Mode"),
                    value: themeProvider.themeMode == ThemeMode.dark,
                    onChanged: (bool value) {
                      Provider.of<ThemeProvider>(context, listen: false)
                          .toggleTheme(value);
                    },
                    activeThumbColor: Theme.of(context).colorScheme.primary,
                  ),
                  ListTile(
                    leading: const Icon(Icons.cleaning_services),
                    title: const Text("Clear Cache"),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Cache cleared (simulation).')),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text("About"),
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'EngagePoint',
                        applicationVersion: '1.0.0',
                        applicationLegalese: '© 2025 ITMDA Group S11',
                        children: <Widget>[
                          const Text(
                              'A mobile engagement app connecting businesses and customers.'),
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
