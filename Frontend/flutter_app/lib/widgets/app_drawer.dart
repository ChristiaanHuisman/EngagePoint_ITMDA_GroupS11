import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart'; 
import '../pages/settings_page.dart';
import '../pages/admin_page.dart';
import '../pages/rewards_page.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  Future<void> _signOut(BuildContext context) async { 
    // Pop the drawer first to avoid errors after sign out
    Navigator.of(context).pop();
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


    return StreamBuilder<UserModel?>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Drawer(child: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Drawer(child: Center(child: Text("Error loading user data.")));
        }

        final UserModel userModel = snapshot.data!;
        final String role = userModel.role;
        final String photoUrl = userModel.photoUrl ??
            user.photoURL ?? 
            'https://static.vecteezy.com/system/resources/previews/009/292/244/non_2x/default-avatar-icon-of-social-media-user-vector.jpg'; // Default avatar

        return Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(userModel.name), 
                accountEmail: Text(userModel.email), 
                currentAccountPicture: CircleAvatar(
                  backgroundImage: NetworkImage(photoUrl),
                  onBackgroundImageError: (exception, stackTrace) {
                    // Handle potential image loading errors
                    debugPrint("Error loading profile image: $exception");
                  },
                  child: photoUrl.isEmpty ? const Icon(Icons.person) : null, 
                ),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
              ),
              ListTile(
                leading: const Icon(Icons.leaderboard_outlined), 
                title: const Text('Rewards & Progression'),
                onTap: () {
                  Navigator.pop(context); 
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const RewardsAndProgressionPage()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined), 
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context); 
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
                },
              ),
              const Divider(),
              if (role == 'admin') 
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings_outlined), 
                  title: const Text('Admin Panel'),
                  onTap: () {
                    Navigator.pop(context); 
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPage()));
                  },
                ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logout', style: TextStyle(color: Colors.red)),
                onTap: () => _signOut(context), 
              ),
            ],
          ),
        );
      },
    );
  }
}