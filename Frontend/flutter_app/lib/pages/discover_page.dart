import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/post_model.dart'; // ADDED: Import the PostModel
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

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(_user.uid).snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.hasData && userSnapshot.data!.exists) {
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
                  prefixIcon: const Icon(Icons.search, color: Colors.white, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white, size: 20),
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
      },
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
        return const Center(child: Text("No posts to discover yet."));
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
      child: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.searchBusinesses(_searchQuery),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LinearProgressIndicator();
          }
          if (snapshot.hasError) {
            return const ListTile(title: Text('Error searching businesses.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const ListTile(title: Text('No businesses found.'));
          }

          final results = snapshot.data!.docs;
          return ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              final business = results[index];
              final businessData = business.data() as Map<String, dynamic>;
              final String name = businessData['name'] ?? 'Unnamed Business';
              final String? photoUrl = businessData['photoUrl'];

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null ? const Icon(Icons.store) : null,
                ),
                title: Text(name),
                onTap: () {
                  FocusScope.of(context).unfocus();
                  _searchController.clear();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfilePage(userId: business.id),
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