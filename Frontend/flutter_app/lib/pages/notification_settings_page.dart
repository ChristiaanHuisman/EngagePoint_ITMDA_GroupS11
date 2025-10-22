import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final List<String> _postTags = ['Promotion', 'Sale', 'Event', 'New Stock', 'Update'];

  void _onTagPreferenceChanged(List<String> currentTags, String tag, bool isSelected) {
    final newTags = List<String>.from(currentTags);
    if (isSelected) {
      newTags.add(tag);
    } else {
      newTags.remove(tag);
    }
    _firestoreService.updateSubscribedTags(newTags);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notification Settings"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: SafeArea(
        child: StreamBuilder<UserModel?>(
          stream: _firestoreService.getUserStream(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
          final user = snapshot.data!;
          final prefs = user.notificationPreferences; // Get the clean preferences object

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              
              const SizedBox(height: 8),

              // Toggles for Customer Notifications
              if (!user.isBusiness) ...[
                SwitchListTile(
                  title: const Text("New Posts"),
                  subtitle: const Text("When a business you follow posts an update"),
                  value: prefs.onNewPost,
                  onChanged: (value) => _firestoreService.updateNotificationPreference('onNewPost', value),
                ),
                SwitchListTile(
                  title: const Text("Review Responses"),
                  subtitle: const Text("When a business replies to your review"),
                  value: prefs.onReviewResponse,
                  onChanged: (value) => _firestoreService.updateNotificationPreference('onReviewResponse', value),
                ),
              ],

              // Toggles for Business Notifications
              if (user.isBusiness) ...[
                SwitchListTile(
                  title: const Text("New Reviews"),
                  subtitle: const Text("When a customer leaves a review"),
                  value: prefs.onNewReview,
                  onChanged: (value) => _firestoreService.updateNotificationPreference('onNewReview', value),
                ),
                SwitchListTile(
                  title: const Text("New Followers"),
                  subtitle: const Text("When someone follows your business"),
                  value: prefs.onNewFollower,
                  onChanged: (value) => _firestoreService.updateNotificationPreference('onNewFollower', value),
                ),
                SwitchListTile(
                  title: const Text("Likes on Your Posts"),
                  subtitle: const Text("When a customer likes one of your posts"),
                  value: prefs.onPostLike,
                  onChanged: (value) => _firestoreService.updateNotificationPreference('onPostLike', value),
                ),
              ],
              
              const Divider(height: 32),
              
              ListTile(
                title: Text("Filter Post Notifications", style: Theme.of(context).textTheme.titleLarge),
                subtitle: const Text("Only get notified about the topics you care about."),
              ),
              Wrap(
                spacing: 8.0,
                children: _postTags.map((tag) {
                  final isSelected = prefs.subscribedTags.contains(tag);
                  return FilterChip(
                    label: Text(tag),
                    selectedColor: Theme.of(context).colorScheme.primaryContainer,
                    selected: isSelected,
                    onSelected: prefs.onNewPost
                        ? (selected) {
                            _onTagPreferenceChanged(prefs.subscribedTags, tag, selected);
                          }
                        : null,
                  );
                }).toList(),
              ),

              const Divider(height: 32),
              
              ListTile(
                title: Text("Quiet Hours", style: Theme.of(context).textTheme.titleLarge),
              ),
              SwitchListTile(
                title: const Text("Mute notifications during quiet hours"),
                value: prefs.quietTimeEnabled,
                onChanged: (value) => _firestoreService.updateNotificationPreference('quietTimeEnabled', value),
              ),
              ListTile(
                title: const Text("From"),
                trailing: Text(prefs.quietTimeStart),
                onTap: () async {
                  final TimeOfDay? time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                  if (time != null) {
                    final formattedTime = "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
                    _firestoreService.updateNotificationPreference('quietTimeStart', formattedTime);
                  }
                },
              ),
              ListTile(
                title: const Text("To"),
                trailing: Text(prefs.quietTimeEnd),
                onTap: () async {
                   final TimeOfDay? time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                  if (time != null) {
                    final formattedTime = "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
                    _firestoreService.updateNotificationPreference('quietTimeEnd', formattedTime);
                  }
                },
              ),
            ],
          );
        },
      ),
    )
    );
  }
}