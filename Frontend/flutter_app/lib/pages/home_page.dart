import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/pages/business_profile_page.dart'; 
import 'package:flutter_app/pages/customer_profile_page.dart';
import 'package:flutter_app/pages/edit_profile_page.dart';
import 'package:flutter_app/widgets/app_drawer.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../widgets/post_card.dart';
import 'login_page.dart';
import 'discover_page.dart'; 
import 'create_post_page.dart';

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedIndex = 0;
  final User? _user = FirebaseAuth.instance.currentUser;


  late final List<Widget> _staticPages;

  @override
  void initState() {
    super.initState();

    // Use _staticPages
    _staticPages = <Widget>[
      FollowingFeed(user: _user), // Page 0
      Container(), // Page 1 Placeholder for Discover
      if (_user != null) // Page 2
        ProfilePageWrapper(userId: _user.uid)
      else
        const Center(child: Text("Not Logged In")),
    ];

    // Listener for the search controller
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

  void onItemTapped(int index) {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }
    // Clear search when changing tabs
    if (_selectedIndex != index && _searchQuery.isNotEmpty) {
      _searchController.clear();
      FocusScope.of(context).unfocus();
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  PreferredSizeWidget? _buildAppBar(BuildContext context, UserModel? userModel) {
    switch (_selectedIndex) {
      case 0: // Home
        return AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          title: const Text('Home'),
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
        );
      case 1: // Discover
        return AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          title: Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(38),
              borderRadius: BorderRadius.circular(30),
            ),
            child: TextField(
              controller: _searchController, 
              style: const TextStyle(color: Colors.white),
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                prefixIcon:
                    const Icon(Icons.search, color: Colors.white, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: Colors.white, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          FocusScope.of(context).unfocus();
                        },
                      )
                    : null,
                hintText: 'Search Businesses...',
                hintStyle: TextStyle(color: Colors.white.withAlpha(179)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(10),
              ),
            ),
          ),
        );
      case 2: // Profile
        return AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          title: Text(userModel?.isBusiness ?? false
              ? 'Business Profile'
              : 'My Profile'),
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                if (userModel != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditProfilePage(user: userModel),
                    ),
                  );
                }
              },
            ),
          ],
        );
      default:
        return null;
    }
  }

  
  Widget? _buildFloatingActionButton(UserModel? userModel) {
    if (_selectedIndex == 0 && userModel?.isBusiness == true) {
      return FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreatePostPage()),
          );
        },
        child: const Icon(Icons.add),
      );
    }
    return null;
  }

  //  HELPER METHOD 
  void _navigateToUserProfileFromSearch(String userId) async {
    // Clear search and unfocus
    _searchController.clear();
    FocusScope.of(context).unfocus();

    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId == currentUserId) {
      // If tapping own profile, switch to profile tab
      onItemTapped(2);
      return;
    }

    UserModel? user = await _firestoreService.getUserProfile(userId);
    if (!mounted) return;
    if (user != null) {
      Navigator.push(
        
        context,
        MaterialPageRoute(
          builder: (context) => user.isBusiness
              ? BusinessProfilePage(userId: userId)
              : CustomerProfilePage(userId: userId),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: _firestoreService.getUserStream(),
      builder: (context, userSnapshot) {
        final userModel = userSnapshot.data;

        return Scaffold(
          key: _scaffoldKey, // Assign the key
          appBar: _buildAppBar(context, userModel), // Use the helper
          drawer: const AppDrawer(), 
          body: SafeArea(
            top: false,
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                _staticPages[0], // Home (index 0)
                DiscoverPageWrapper(
                  // Discover (index 1)
                  searchQuery: _searchQuery,
                  onNavigate: _navigateToUserProfileFromSearch,
                ),
                _staticPages[2], // Profile (index 2)
              ],
            ),
          ),
          floatingActionButton:
              _buildFloatingActionButton(userModel), 
          bottomNavigationBar: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.explore), label: 'Discover'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person), label: 'Profile'),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            onTap: onItemTapped, 
          ),
        );
      },
    );
  }
}

class ProfilePageWrapper extends StatelessWidget {
  final String userId;
  final FirestoreService _firestoreService = FirestoreService();

  ProfilePageWrapper({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: _firestoreService.getUserProfile(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text("Error loading profile data."));
        }

        final user = snapshot.data!;


        if (user.isBusiness) {
          return BusinessProfilePage(userId: userId, isMainPage: true);
        } else {
          return CustomerProfilePage(userId: userId, isMainPage: true);
        }
      },
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


  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.user == null) {
      return const Center(child: Text("Not logged in."));
    }
    return _buildFollowedFeed();
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