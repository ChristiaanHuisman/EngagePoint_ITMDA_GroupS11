import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    
    return DefaultTabController(
      length: 2, // The number of tabs
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Admin Dashboard"),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.verified_user_outlined), text: 'Verification'),
              Tab(icon: Icon(Icons.flag_outlined), text: 'Moderation'),
            ],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
          ),
        ),
        
        body: TabBarView(
          children: [
            // Content for the "Business Verification" tab
            _buildBusinessVerificationView(),
            
            // Content for the "Content Moderation" tab 
            _buildContentModerationView(),
          ],
        ),
      ),
    );
  }

  /// Builds the UI for the business verification queue.
  Widget _buildBusinessVerificationView() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getPendingBusinesses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text("Something went wrong."));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "No businesses are currently pending verification.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        final pendingBusinesses = snapshot.data!.docs;

        return ListView.builder(
          itemCount: pendingBusinesses.length,
          itemBuilder: (context, index) {
            final business = pendingBusinesses[index];
            final data = business.data() as Map<String, dynamic>;
            final String name = data['name'] ?? 'No Name';
            final String email = data['email'] ?? 'No Email';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(email, style: TextStyle(color: Colors.grey[600])),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            _firestoreService.updateUserStatus(business.id, 'rejected');
                          },
                          child: const Text('Reject', style: TextStyle(color: Colors.red)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            _firestoreService.updateUserStatus(business.id, 'verified');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Approve'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Builds the placeholder UI for the content moderation queue.
  Widget _buildContentModerationView() {
    // This is currently a placeholder. 
    // replace this with a StreamBuilder that listens for posts
    // with a status of 'needs_moderation'.
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flag_circle_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              "Content Moderation",
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Posts flagged by the Python moderation service for review will appear here.",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
