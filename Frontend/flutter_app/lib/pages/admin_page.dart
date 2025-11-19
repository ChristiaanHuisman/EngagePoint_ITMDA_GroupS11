import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
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
      length: 2, 
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Admin Dashboard"),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          bottom: TabBar(
            tabs: const [
              Tab(
                  icon: Icon(Icons.verified_user_outlined),
                  text: 'Verification'),
              Tab(icon: Icon(Icons.flag_outlined), text: 'Moderation'),
            ],
            indicatorColor: Theme.of(context).colorScheme.onPrimary,
            labelColor: Theme.of(context).colorScheme.onPrimary,
            unselectedLabelColor: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              _buildBusinessVerificationView(),
              _buildContentModerationView(),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the UI for the business verification queue.
  Widget _buildBusinessVerificationView() {
    return StreamBuilder<List<UserModel>>(
      stream: _firestoreService.getPendingBusinesses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text("Something went wrong."));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              "No businesses are currently pending verification.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        final pendingBusinesses = snapshot.data!;

        return ListView.builder(
          itemCount: pendingBusinesses.length,
          itemBuilder: (context, index) {
            final business = pendingBusinesses[index];

            String requestedAt = 'Unknown request time';
            if (business.verificationRequestedAt != null) {
              requestedAt = DateFormat('MMM dd, yyyy - hh:mm a')
                  .format(business.verificationRequestedAt!.toDate());
            }

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(business.name,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(business.email,
                        style: TextStyle(color: Colors.grey[600])),
                    const SizedBox(height: 8),
                    Text('Requested: $requestedAt',
                        style: TextStyle(
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                            fontSize: 12)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            _firestoreService.rejectBusiness(business.uid);
                          },
                          child: const Text('Reject',
                              style: TextStyle(color: Colors.red)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            _firestoreService.approveBusiness(business.uid);
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

  Widget _buildContentModerationView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flag_circle_outlined,
                size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              "Content Moderation",
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Future plans for content moderation will be implemented here.",
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}