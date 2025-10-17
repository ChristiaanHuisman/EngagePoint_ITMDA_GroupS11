import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/settings_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final List<String> _postTags = [
    'Promotion',
    'Sale',
    'Event',
    'New Stock',
    'Update'
  ];

  void _onPreferenceChanged(
      List<String> currentPrefs, String tag, bool isSelected) {
    // This function remains the same
    final newPrefs = List<String>.from(currentPrefs);
    if (isSelected) {
      newPrefs.add(tag);
    } else {
      newPrefs.remove(tag);
    }
    _firestoreService.updateNotificationPreferences(newPrefs);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: StreamBuilder<UserModel?>(
        stream: _firestoreService.getUserStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data;

          if (user == null) {
            return const Center(child: Text("Could not load settings."));
          }

          // Determine if filtering is enabled based on the data from the model
          final bool tagFilteringEnabled = user.notificationTags.isNotEmpty;

          return Consumer<SettingsData>(
            builder:
                (BuildContext context, SettingsData settings, Widget? child) {
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

                    // Master switch for all notifications
                    SwitchListTile(
                      title: const Text("Receive Notifications"),
                      value: settings.receiveNotifications,
                      onChanged: (bool value) {
                        settings.receiveNotifications = value;
                      },
                      activeThumbColor: Theme.of(context).colorScheme.primary,
                    ),

                    SwitchListTile(
                      title: const Text("Filter Notifications by Tag"),
                      subtitle: const Text(
                          "Only receive notifications for topics you select."),
                      value: tagFilteringEnabled,
                      onChanged: (bool value) {
                        // When the user toggles this switch, we update Firestore.
                        // The StreamBuilder will then automatically rebuild the UI.
                        if (value) {
                          // If turning on, default to all tags selected.
                          _firestoreService
                              .updateNotificationPreferences(_postTags);
                        } else {
                          // If turning off, clear the preferences.
                          _firestoreService.updateNotificationPreferences([]);
                        }
                      },
                      activeThumbColor: Theme.of(context).colorScheme.primary,
                    ),

                    if (tagFilteringEnabled)
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 16.0, right: 16.0, top: 8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: _postTags.map((tag) {
                              return CheckboxListTile(
                                title: Text(tag),
                                value: user.notificationTags.contains(tag),
                                onChanged: (bool? value) {
                                  if (value != null) {
                                    _onPreferenceChanged(
                                        user.notificationTags, tag, value);
                                  }
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ),

                    const Divider(height: 32),

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

                    const Divider(height: 32),

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
                      activeThumbColor: Theme.of(context).colorScheme.primary,
                    ),
                    ListTile(
                      leading: const Icon(Icons.cleaning_services),
                      title: const Text("Clear Cache"),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Cache cleared.')),
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
                          applicationLegalese: '© 2024 ITMDA Group S11',
                          children: <Widget>[
                            const Text('A mobile engagement app.'),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
