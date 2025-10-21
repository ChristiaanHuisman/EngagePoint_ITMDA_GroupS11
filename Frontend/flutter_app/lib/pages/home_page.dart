import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/widgets/app_drawer.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../widgets/post_card.dart';
import 'login_page.dart';
import 'discover_page.dart';
import 'create_post_page.dart';
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
  State<MainAppNavigator> createState() => MainAppNavigatorState();
}

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
      if (_user != null)
        UserProfilePage(userId: _user.uid)
      else
        const Center(child: Text("Not Logged In")),
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
      body: SafeArea(
        top: false,
        child: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Discover'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (_searchQuery != _searchController.text) {
        setState(() {
          _searchQuery = _searchController.text;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.user == null) {
      return const Center(child: Text("Not logged in."));
    }

    return StreamBuilder<UserModel?>(
      stream: _firestoreService.getUserStream(),
      builder: (context, userSnapshot) {
        final userModel = userSnapshot.data;
        if (userSnapshot.connectionState == ConnectionState.waiting ||
            userModel == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Home')),
            drawer: const Drawer(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            title: const Text('Home'),
          ),
          drawer: const AppDrawer(),
          floatingActionButton: userModel.isBusiness
              ? FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CreatePostPage()));
                  },
                  child: const Icon(Icons.add),
                )
              : null,
          body: _buildFollowedFeed(),
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
        if (followedSnapshot.hasError ||
            !followedSnapshot.hasData ||
            followedSnapshot.data!.isEmpty) {
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

        return StreamBuilder<List<PostModel>>(
          stream: _firestoreService.getFollowedPosts(followedBusinessIds),
          builder: (context, postSnapshot) {
            if (postSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!postSnapshot.hasData || postSnapshot.data!.isEmpty) {
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

            final posts = postSnapshot.data!;
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
