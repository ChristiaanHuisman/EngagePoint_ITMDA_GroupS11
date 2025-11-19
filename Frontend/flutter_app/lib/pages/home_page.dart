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
import 'business_profile_page.dart';
import 'customer_profile_page.dart';

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _pages = <Widget>[
      FollowingFeed(user: _user, scaffoldKey: _scaffoldKey),
      DiscoverPage(scaffoldKey: _scaffoldKey),
      if (_user != null)
        ProfilePageWrapper(userId: _user.uid, scaffoldKey: _scaffoldKey)
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
      key: _scaffoldKey,
      drawer: const AppDrawer(),
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

// This wrapper checks the users role and loads the correct profile page
class ProfilePageWrapper extends StatelessWidget {
  final String userId;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final FirestoreService _firestoreService = FirestoreService();

  ProfilePageWrapper(
      {super.key, required this.userId, required this.scaffoldKey});

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
          return BusinessProfilePage(
            userId: userId,
            scaffoldKey: scaffoldKey,
            isMainPage: true,
          );
        } else {
          return CustomerProfilePage(
            userId: userId,
            scaffoldKey: scaffoldKey,
            isMainPage: true,
          );
        }
      },
    );
  }
}

class FollowingFeed extends StatefulWidget {
  final User? user;
  final GlobalKey<ScaffoldState> scaffoldKey;
  const FollowingFeed({super.key, this.user, required this.scaffoldKey});

  @override
  State<FollowingFeed> createState() => _FollowingFeedState();
}

class _FollowingFeedState extends State<FollowingFeed> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  String _sortBy = 'createdAt'; // Default sort by date
  String? _selectedTag;
  final List<String> _postTags = [
    'Promotion',
    'Sale',
    'Event',
    'New Stock',
    'Update'
  ];

  late Stream<List<String>> _followedBusinessesStream;

  @override
  void initState() {
    super.initState();
    _followedBusinessesStream = _firestoreService.getFollowedBusinesses();
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

 Widget _buildFilterBar() {
    final Color borderColor = Colors.grey.shade400;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 5.0),
      child: Row(
        children: [
          // Sort By Dropdown (Date & Likes)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0), 
            
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _sortBy,
                items: const [
                  DropdownMenuItem(value: 'createdAt', child: Text('Most Recent')),
                  DropdownMenuItem(value: 'reactionCount', child: Text('Most Liked')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _sortBy = value;
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Horizontal Tag List
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _postTags.map((tag) {
                  final bool isSelected = _selectedTag == tag;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: FilterChip(
                      label: Text(tag),
                      selectedColor: Theme.of(context).colorScheme.primaryContainer,
                      selected: isSelected,

                      shape: StadiumBorder(
                        side: BorderSide(color: borderColor, width: 1.0),
                      ),

                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedTag = tag;
                          } else {
                            _selectedTag = null; // De-select
                          }
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.user == null) {
      return const Center(child: Text("Not logged in."));
    }

    return StreamBuilder<UserModel?>(
      stream: _firestoreService.getUserStream(),
      builder: (context, userSnapshot) {
        
        // 1. Wait for connection
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final userModel = userSnapshot.data;

        // 2. FIX: Handling Null Data safely
        // If data is null, it might just be loading the new document. 
        // DO NOT LOG OUT. Just wait.
        if (userModel == null) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text("Setting up your profile..."),
                ],
              ),
            ),
          );
        }

        // 3. Data Loaded - Show the Feed
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            title: const Text('Home'),
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => widget.scaffoldKey.currentState?.openDrawer(),
              ),
            ),
          ),
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
          body: SafeArea(
            child: Column(
              children: [
                _buildFilterBar(),
                Expanded(
                  child: _buildFollowedFeed(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

 Widget _buildFollowedFeed() {
  return StreamBuilder<List<String>>(
    stream: _followedBusinessesStream,
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
        stream: _firestoreService.getFollowedPosts(
          followedBusinessIds,
          sortBy: _sortBy,
        ),
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

          final allPosts = postSnapshot.data!;
          
          final filteredPosts = allPosts.where((post) {
            // 1. If no tag is selected in the UI, show all posts
            if (_selectedTag == null) {
              return true;
            }

            // 2. FIX: Handle posts that don't have a tag.
            // If a post's tag is null, it cannot match the selected tag, so return false.
            if (post.tag == null) {
              return false;
            }

            // 3. Now it is safe to check because we know it isn't null
            return post.tag!.contains(_selectedTag!);
          }).toList();

          if (filteredPosts.isEmpty) {
            if (_selectedTag != null) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "No posts match that tag.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ),
              );
            }
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

          return ListView.builder(
            itemCount: filteredPosts.length, // Use filtered list
            itemBuilder: (context, index) =>
                PostCard(post: filteredPosts[index]), // Use filtered list
          );
        },
      );
    },
  );
}
}