import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../widgets/post_card.dart';
import 'user_profile_page.dart';
import '../widgets/app_drawer.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final User? _user = FirebaseAuth.instance.currentUser;

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
    if (_user == null) {
      return const Scaffold(body: Center(child: Text("Not Logged In")));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
      ),
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          _buildDiscoverFeed(),
          if (_searchQuery.trim().isNotEmpty) _buildSearchResults(),
        ],
      ),
    );
  }

  Widget _buildDiscoverFeed() {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<List<PostModel>>(
      stream: _firestoreService.getAllPosts(),
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

  Widget _buildSearchResults() {
    return Container(
      color: Colors.white,
      // StreamBuilder now expects List<UserModel>
      child: StreamBuilder<List<UserModel>>(
        stream: _firestoreService.searchBusinesses(_searchQuery),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LinearProgressIndicator();
          }
          if (snapshot.hasError) {
            return const ListTile(title: Text('Error searching businesses.'));
          }
          // Check the list directly instead of snapshot.data!.docs
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const ListTile(title: Text('No businesses found.'));
          }

          // The data is already a List<UserModel>!
          final results = snapshot.data!;

          return ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              // No more manual parsing! 'business' is already a UserModel.
              final UserModel business = results[index];

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: business.photoUrl != null
                      ? NetworkImage(business.photoUrl!)
                      : null,
                  child: business.photoUrl == null
                      ? const Icon(Icons.store)
                      : null,
                ),
                title: Text(business.name),
                onTap: () {
                  FocusScope.of(context).unfocus();
                  _searchController.clear();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          UserProfilePage(userId: business.uid),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
