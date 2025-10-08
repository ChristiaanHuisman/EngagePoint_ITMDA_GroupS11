import 'package:cloud_firestore/cloud_firestore.dart'; // <-- FIX APPLIED: Corrected the import path
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // We will create this 'getPendingBusinesses' method in the next step
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
                              // We will create this 'updateUserStatus' method next
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
      ),
    );
  }
}

