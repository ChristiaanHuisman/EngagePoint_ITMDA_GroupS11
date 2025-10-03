import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/settings_data.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: Consumer<SettingsData>(
        builder: (BuildContext context, SettingsData settings, Widget? child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
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
                  value: settings.receiveNotifications,
                  onChanged: (bool value) {
                    settings.receiveNotifications = value;
                  },
                  activeThumbColor: Colors.white,
                  activeTrackColor: Colors.deepPurple,
                  inactiveThumbColor: Colors.grey[700],
                  inactiveTrackColor: Colors.grey[400],
                ),
                SwitchListTile(
                  title: const Text("Context Notifications"),
                  subtitle: settings.receiveNotifications
                      ? null
                      : const Text("Enable 'Receive Notifications' first"),
                  value: settings.contextNotificationsEnabled,
                  onChanged: settings.receiveNotifications
                      ? (bool value) {
                          settings.contextNotificationsEnabled = value;
                        }
                      : null,
                  activeThumbColor: Colors.white,
                  activeTrackColor: Colors.deepPurple,
                  inactiveThumbColor: Colors.grey[700],
                  inactiveTrackColor: Colors.grey[400],
                ),
                if (settings.receiveNotifications && settings.contextNotificationsEnabled)
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Column(
                      children: <Widget>[
                        CheckboxListTile(
                          title: const Text("Suggested Accounts"),
                          value: settings.suggestedAccountsNotifications,
                          onChanged: (bool? value) {
                            settings.suggestedAccountsNotifications = value ?? false;
                          },
                        ),
                        CheckboxListTile(
                          title: const Text("Rewards"),
                          value: settings.rewardsNotifications,
                          onChanged: (bool? value) {
                            settings.rewardsNotifications = value ?? false;
                          },
                        ),
                      ],
                    ),
                  ),
                const Divider(),
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
                  value: settings.privateProfile,
                  onChanged: (bool? value) {
                    settings.privateProfile = value ?? false;
                  },
                ),
                CheckboxListTile(
                  title: const Text("Anonymous Rewards"),
                  value: settings.anonymousRewards,
                  onChanged: (bool? value) {
                    settings.anonymousRewards = value ?? false;
                  },
                ),
                CheckboxListTile(
                  title: const Text("Track Analytics"),
                  value: settings.trackAnalytics,
                  onChanged: (bool? value) {
                    settings.trackAnalytics = value ?? false;
                  },
                ),
                const Divider(),
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
                  value: settings.darkModeEnabled,
                  onChanged: (bool value) {
                    settings.darkModeEnabled = value;
                  },
                  activeThumbColor: Colors.white,
                  activeTrackColor: Colors.deepPurple,
                  inactiveThumbColor: Colors.grey[700],
                  inactiveTrackColor: Colors.grey[400],
                ),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text("Help"),
                  onTap: () {
                    debugPrint('Help tapped');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Opening help documentation...'),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.cleaning_services),
                  title: const Text("Clear Cache"),
                  onTap: () {
                    debugPrint('Clear Cache tapped');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cache cleared.')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text("About"),
                  onTap: () {
                    debugPrint('About tapped');
                    showAboutDialog(
                      context: context,
                      applicationName: 'Login and Home App',
                      applicationVersion: '1.0.0',
                      applicationLegalese: '© 2023 Example Company',
                      children: <Widget>[
                        const Text('This is a demonstration application.'),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}