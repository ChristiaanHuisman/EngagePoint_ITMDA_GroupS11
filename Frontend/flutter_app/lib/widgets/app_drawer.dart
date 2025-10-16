import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../pages/settings_page.dart';
import '../pages/admin_page.dart';
import '../pages/rewards_page.dart';
// For MainAppNavigatorState

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  Future<void> _signOut() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Drawer(
        child: Center(child: Text("Not logged in.")),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        Map<String, dynamic> userData = {};
        String role = 'customer';

        if (snapshot.hasData && snapshot.data!.exists) {
          userData = snapshot.data!.data() as Map<String, dynamic>;
          role = userData['role'] ?? 'customer';
        }

        String photoUrl = userData['photoUrl'] ??
            user.photoURL ??
            'https://static.vecteezy.com/system/resources/previews/009/292/244/non_2x/default-avatar-icon-of-social-media-user-vector.jpg';

        return Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(userData['name'] ?? user.displayName ?? 'User'),
                accountEmail: Text(user.email ?? 'No email'),
                currentAccountPicture: CircleAvatar(
                  backgroundImage: NetworkImage(photoUrl),
                ),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
              ),
              
              
              ListTile(
                leading: const Icon(Icons.leaderboard),
                title: const Text('Rewards & Progression'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const RewardsAndProgressionPage()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
                },
              ),
              const Divider(),
              if (role == 'admin')
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings),
                  title: const Text('Admin Panel'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPage()));
                  },
                ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logout', style: TextStyle(color: Colors.red)),
                onTap: _signOut,
              ),
            ],
          ),
        );
      },
    );
  }
}
