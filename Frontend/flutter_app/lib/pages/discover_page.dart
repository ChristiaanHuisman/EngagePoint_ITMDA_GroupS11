import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/pages/business_profile_page.dart';
import 'package:flutter_app/pages/customer_profile_page.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../widgets/post_card.dart';
import '../widgets/app_drawer.dart';

class DiscoverPage extends StatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;
  const DiscoverPage({super.key, required this.scaffoldKey});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
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

  void _navigateToUserProfile(String userId) async {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId == currentUserId) {
      if (Navigator.canPop(context)) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
      return;
    }

    if (!mounted) return;

    UserModel? user = await _firestoreService.getUserProfile(userId);

    if (!mounted) return;

    if (user != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => user.isBusiness
              ? BusinessProfilePage(
                  userId: userId,
                  scaffoldKey: widget.scaffoldKey ?? GlobalKey<ScaffoldState>())
              : CustomerProfilePage(
                  userId: userId,
                  scaffoldKey:
                      widget.scaffoldKey ?? GlobalKey<ScaffoldState>()),
        ),
      );

      if (!mounted) return;

      _searchController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color onPrimaryColor = Theme.of(context).colorScheme.onPrimary;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: onPrimaryColor,
        leading: widget.scaffoldKey != null
            ? IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => widget.scaffoldKey!.currentState?.openDrawer(),
              )
            : Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: onPrimaryColor.withAlpha(38),
            borderRadius: BorderRadius.circular(30),
          ),
          child: TextField(
            controller: _searchController,
            style: TextStyle(color: onPrimaryColor),
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search, color: onPrimaryColor, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: onPrimaryColor, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        FocusScope.of(context).unfocus();
                      },
                    )
                  : null,
              hintText: 'Search Businesses...',
              hintStyle: TextStyle(color: onPrimaryColor.withAlpha(179)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(10),
            ),
          ),
        ),
      ),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: DiscoverPageWrapper(
          searchQuery: _searchQuery,
          onNavigate: _navigateToUserProfile,
        ),
      ),
    );
  }
}

// Wrapper widget passes the onNavigate function down
class DiscoverPageWrapper extends StatelessWidget {
  final String searchQuery;
  final Function(String) onNavigate;

  const DiscoverPageWrapper({
    super.key,
    required this.searchQuery,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const DiscoverFeed(),
        if (searchQuery.trim().isNotEmpty)
          DiscoverSearchResults(
            searchQuery: searchQuery,
            onNavigate: onNavigate, // Pass the function to the results
          ),
      ],
    );
  }
}

// This feed widget shows all posts
class DiscoverFeed extends StatelessWidget {
  const DiscoverFeed({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<List<PostModel>>(
      stream: firestoreService.getAllPosts(),
      builder: (context, postSnapshot) {
        if (postSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (postSnapshot.hasError) {
          return const Center(child: Text("Something went wrong."));
        }
        if (!postSnapshot.hasData || postSnapshot.data!.isEmpty) {
          return const Center(child: Text("No posts to discover yet."));
        }

        final posts = postSnapshot.data!
            .where((post) => post.businessId != currentUserId)
            .toList();

        if (posts.isEmpty) {
          return const Center(
              child: Text("No other businesses have posted yet."));
        }

        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) => PostCard(post: posts[index]),
        );
      },
    );
  }
}

class DiscoverSearchResults extends StatelessWidget {
  final String searchQuery;
  final Function(String) onNavigate;
  final FirestoreService _firestoreService = FirestoreService();

  DiscoverSearchResults({
    super.key,
    required this.searchQuery,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: StreamBuilder<List<UserModel>>(
        stream: _firestoreService.searchBusinesses(searchQuery),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LinearProgressIndicator();
          }
          if (snapshot.hasError) {
            return const ListTile(title: Text('Error searching businesses.'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const ListTile(title: Text('No businesses found.'));
          }

          final results = snapshot.data!;
          return ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              final UserModel business = results[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: business.photoUrl != null
                      ? NetworkImage(business.photoUrl!)
                      : null,
                  child: business.photoUrl == null
                      ? Icon(business.isBusiness ? Icons.store : Icons.person)
                      : null,
                ),
                title: Text(business.name),
                onTap: () {
                  onNavigate(business.uid);
                },
              );
            },
          );
        },
      ),
    );
  }
}
