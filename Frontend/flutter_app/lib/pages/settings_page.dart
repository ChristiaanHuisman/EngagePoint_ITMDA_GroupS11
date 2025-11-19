import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/theme_provider.dart';
import '../services/firestore_service.dart';
import 'notification_settings_page.dart';
import '../services/auth_service.dart';
import 'login_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool? _autoReplyLocalValue; 
  bool _isLoadingAutoReply = true; 
  final AuthService _authService = AuthService();
  bool _isDeleting = false;

  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAutoReplyValue();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadAutoReplyValue() async {
    final FirestoreService firestoreService = FirestoreService();
    final value = await firestoreService.getAutoResponseStatus();
    if (mounted) {
      setState(() {
        _autoReplyLocalValue = value;
        _isLoadingAutoReply = false;
      });
    }
  }

  Future<void> _showDeleteConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: !_isDeleting, 
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Are you sure?'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('You are about to permanently delete your account.'),
                SizedBox(height: 8),
                Text('This action cannot be undone.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop(); 
                _deleteAccount(); 
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showReAuthDialog() async {
    _passwordController.clear(); 
    return showDialog<void>(
      context: context,
      barrierDismissible: false, 
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Recent Login Required'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text(
                    'This action is sensitive. Please enter your password to confirm.'),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Confirm & Delete'),
              onPressed: () {
                final password = _passwordController.text;
                Navigator.of(context).pop(); 
                _reAuthenticateAndDelete(password);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _reAuthenticateAndDelete(String password) async {
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password cannot be empty.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isDeleting = true; 
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in.');
      }

      final email = user.email;
      if (email == null || email.isEmpty) {
        throw Exception('User email is not available for re-authentication.');
      }

      final credential =
          EmailAuthProvider.credential(email: email, password: password);
      await user.reauthenticateWithCredential(credential);

      await _authService.deleteUserAccount();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (Route<dynamic> route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isDeleting = false;
      });

      String message = 'Delete failed: ${e.message ?? e.code}';
      if (e.code == 'wrong-password') {
        message = 'Delete failed: Wrong password.';
      } else if (e.code == 'user-mismatch') {
        message = 'Delete failed: User mismatch.';
      } else if (e.code == 'user-not-found') {
        message = 'Delete failed: User not found.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delete failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isDeleting = false;
      });
    }
  }

  //  HANDLES DELETION LOGIC
  Future<void> _deleteAccount() async {
    setState(() {
      _isDeleting = true;
    });

    try {
      await _authService.deleteUserAccount();

      if (!mounted) return;
      // On success navigate out of the app to the login screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
            builder: (context) => const LoginPage()), 
        (Route<dynamic> route) => false,
      );
    
    } on FirebaseAuthException catch (e) { 
      if (!mounted) return;
      setState(() {
        _isDeleting = false; 
      });

      if (e.code == 'requires-recent-login') {
        // Show the re-auth dialog
        _showReAuthDialog();
      
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete failed: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delete failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isDeleting = false;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Stack(
      children: [
        Scaffold(
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
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _authService.signOut();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (context) => const LoginPage()),
                      (Route<dynamic> route) => false,
                    );
                  });

                  // Show a loader while we are navigating away
                  return const Center(child: CircularProgressIndicator());
                }

                final prefs = user.notificationPreferences;
                final bool receiveNotificationsEnabled = prefs.onNewPost;

                // Initialize local auto-reply value if not set
                _autoReplyLocalValue ??= prefs.onReviewResponse;

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
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                      SwitchListTile(
                        title: const Text("Receive Notifications"),
                        subtitle: const Text(
                            "Enable/disable detailed settings below"),
                        value: receiveNotificationsEnabled,
                        onChanged: (bool value) {
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
                                builder: (_) =>
                                    const NotificationSettingsPage()),
                          );
                        },
                      ),

                      const Divider(height: 32),

                      // Privacy Section
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          "Privacy",
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
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

                      // Auto-reply Section (Business users only)
                      if (user.isBusiness) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            "Auto-reply for Reviews",
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        _isLoadingAutoReply
                            ? const Center(child: CircularProgressIndicator())
                            : SwitchListTile(
                                title: const Text("Enable Auto-reply"),
                                subtitle: const Text(
                                    "Automatically send responses to reviews (businesses can still edit them)"),
                                value: _autoReplyLocalValue!,
                                onChanged: (bool value) async {
                                  setState(() {
                                    _autoReplyLocalValue = value;
                                  });
                                  if (value) {
                                    await firestoreService.enableAutoResponse();
                                  } else {
                                    await firestoreService
                                        .disableAutoResponse();
                                  }
                                },
                                activeThumbColor:
                                    Theme.of(context).colorScheme.primary,
                              ),
                        const Divider(height: 32),
                      ],

                      // App Section
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          "App",
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
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
                      const Divider(height: 32),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          "Account",
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                      ListTile(
                        leading: Icon(Icons.delete_forever,
                            color: Colors.red.shade700),
                        title: Text(
                          "Delete Account",
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                        subtitle: const Text(
                            "Permanently delete your account and data"),
                        onTap:
                            _showDeleteConfirmationDialog, // Triggers the dialog
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),

        // LOADING OVERLAY
        if (_isDeleting)
          Container(
            color: Colors.black,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Deleting your account...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
