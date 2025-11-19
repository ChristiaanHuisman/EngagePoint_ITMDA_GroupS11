import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../pages/settings_page.dart';
import '../pages/admin_page.dart';
import '../pages/business_dashboard_page.dart';
import '../pages/rewards_page.dart';
import '../services/auth_service.dart';
import '../pages/login_page.dart';


class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  Future<void> _signOut(BuildContext context) async {

    Navigator.of(context).pop();

    final AuthService authService = AuthService();
    await authService.signOut();

    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Drawer(
        child: Center(child: Text("Not logged in.")),
      );
    }

    return StreamBuilder<UserModel?>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Drawer(
              child: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Drawer(
              child: Center(child: Text("Error loading user data.")));
        }

        final UserModel userModel = snapshot.data!;
        final String role = userModel.role;
        final String photoUrl = userModel.photoUrl ??
            user.photoURL ??
            'https://static.vecteezy.com/system/resources/previews/009/292/244/non_2x/default-avatar-icon-of-social-media-user-vector.jpg'; // Default avatar

        final Color headerTextColor = Theme.of(context).colorScheme.onPrimary;

        return Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(
                  userModel.name,
                  style: TextStyle(
                    color: headerTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                accountEmail: Text(
                  userModel.email,
                  style: TextStyle(
                    color: headerTextColor,
                  ),
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundImage: NetworkImage(photoUrl),
                  onBackgroundImageError: (exception, stackTrace) {
                    debugPrint("Error loading profile image: $exception");
                  },
                  child: photoUrl.isEmpty ? const Icon(Icons.person) : null,
                ),
                decoration:
                    BoxDecoration(color: Theme.of(context).colorScheme.primary),
              ),
              if (role == 'business')
              ListTile(
                leading: const Icon(Icons.query_stats_outlined),
              title: const Text('Business Dashboard'),
              onTap: () {
                Navigator.pop(context); 
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const BusinessDashboardPage()),
                );
              },
            ),
              ListTile(
                leading: const Icon(Icons.leaderboard_outlined),
                title: const Text('Rewards & Progression'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RewardsAndProgressionPage()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SettingsPage()));
                },
              ),
              
            
              const Divider(),
              if (role == 'admin')
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings_outlined),
                  title: const Text('Admin Panel'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const AdminPage()));
                  },
                ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logout', style: TextStyle(color: Colors.red)),
                onTap: () => _signOut(context), // Calls our updated function
              ),
            ],
          ),
        );
      },
    );
  }
}
