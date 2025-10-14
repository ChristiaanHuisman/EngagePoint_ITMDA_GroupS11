import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/firestore_service.dart';
import '../widgets/post_card.dart';
import 'login_page.dart';
import 'discover_page.dart';
import 'create_post_page.dart';
import 'rewards_page.dart';
import 'settings_page.dart';
import 'admin_page.dart';
import 'user_profile_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (authSnapshot.hasData) {
          return const MainAppNavigator();
        }

        return const LoginPage();
      },
    );
  }
}

class MainAppNavigator extends StatefulWidget {
  const MainAppNavigator({super.key});

  @override
  // FIX 1/3: Return the new public state class name.
  State<MainAppNavigator> createState() => MainAppNavigatorState();
}

// FIX 2/3: The state class is now public (no leading underscore).
class MainAppNavigatorState extends State<MainAppNavigator> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;
  final User? _user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _pages = <Widget>[
      FollowingFeed(user: _user),
      const DiscoverPage(),
      
      if (_user != null) UserProfilePage(userId: _user.uid) else const Center(child: Text("Not Logged In")),
      
    ];
  }

  void onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Discover',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        onTap: onItemTapped,
      ),
    );
  }
}

class FollowingFeed extends StatefulWidget {
  final User? user;
  const FollowingFeed({super.key, this.user});

  @override
  State<FollowingFeed> createState() => _FollowingFeedState();
}

class _FollowingFeedState extends State<FollowingFeed> {
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> _signOut() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.user == null) {
      return const Center(child: Text("Not logged in."));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.user!.uid).snapshots(),
      builder: (context, userSnapshot) {
        String role = 'customer';
        Map<String, dynamic> userData = {};

        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          userData = userSnapshot.data!.data() as Map<String, dynamic>;
          role = userData['role'] ?? 'customer';
        }
        
        String photoUrl = userData['photoUrl'] ?? widget.user!.photoURL ??
            'https://static.vecteezy.com/system/resources/previews/009/292/244/non_2x/default-avatar-icon-of-social-media-user-vector.jpg';

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            title: const Text('Home'),
          ),
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
                  accountName: Text(userData['name'] ?? widget.user!.displayName ?? 'User'),
                  accountEmail: Text(widget.user!.email ?? 'No email'),
                  currentAccountPicture: CircleAvatar(
                    backgroundImage: NetworkImage(photoUrl),
                  ),
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
                ),
                ListTile(leading: const Icon(Icons.home), title: const Text('Home'), onTap: () => Navigator.pop(context)),
                ListTile(
                  leading: const Icon(Icons.explore),
                  title: const Text('Discover'),
                  onTap: () {
                    Navigator.pop(context);
                    // FIX 3/3: Use the public state type here.
                    final navState = context.findAncestorStateOfType<MainAppNavigatorState>();
                    navState?.onItemTapped(1);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Profile'),
                  onTap: () {
                    Navigator.pop(context);
                    // FIX 3/3: Use the public state type here.
                    final navState = context.findAncestorStateOfType<MainAppNavigatorState>();
                    navState?.onItemTapped(2);
                  },
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
          ),
          floatingActionButton: role == 'business'
              ? FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreatePostPage()),
                    );
                  },
                  child: const Icon(Icons.add),
                )
              : null,
          body: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: ToggleButtons(
                    isSelected: [true, false],
                    onPressed: (int index) {
                      if (index == 1) {
                         final navState = context.findAncestorStateOfType<MainAppNavigatorState>();
                         navState?.onItemTapped(1);
                      }
                    },
                    borderRadius: BorderRadius.circular(30.0),
                    borderColor: Colors.grey.shade300,
                    selectedBorderColor: Theme.of(context).colorScheme.primary,
                    constraints: const BoxConstraints(minHeight: 38.0, minWidth: 100.0),
                    selectedColor: Colors.white,
                    fillColor: Theme.of(context).colorScheme.primary,
                    color: Theme.of(context).colorScheme.primary,
                    children: const [
                      Padding(padding: EdgeInsets.symmetric(horizontal: 16.0), child: Text('Following')),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 16.0), child: Text('Discover')),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: _buildFollowedFeed(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFollowedFeed() {
    return StreamBuilder<List<String>>(
      stream: _firestoreService.getFollowedBusinesses(),
      builder: (context, followedSnapshot) {
        if (followedSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (followedSnapshot.hasError) {
          return const Center(child: Text("Error fetching followed businesses."));
        }
        if (!followedSnapshot.hasData || followedSnapshot.data!.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Your feed is empty.\nGo to Discover to find and follow businesses!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ),
          );
        }
        final followedBusinessIds = followedSnapshot.data!;
        return StreamBuilder<QuerySnapshot>(
          stream: _firestoreService.getFollowedPosts(followedBusinessIds),
          builder: (context, postSnapshot) {
            if (postSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (postSnapshot.hasError) {
              debugPrint("Error fetching followed posts: ${postSnapshot.error}");
              return const Center(child: Text("Something went wrong loading posts."));
            }
            if (!postSnapshot.hasData || postSnapshot.data!.docs.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "The businesses you follow haven't posted anything yet.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ),
              );
            }
            final posts = postSnapshot.data!.docs;
            return ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) => PostCard(post: posts[index]),
            );
          },
        );
      },
    );
  }
}
