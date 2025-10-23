import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/location_model.dart';
import '../services/firestore_service.dart';

class ManageLocationsPage extends StatefulWidget {
  const ManageLocationsPage({super.key});

  @override
  State<ManageLocationsPage> createState() => _ManageLocationsPageState();
}

class _ManageLocationsPageState extends State<ManageLocationsPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final String? _businessId = FirebaseAuth.instance.currentUser?.uid;

  void _showLocationDialog({LocationModel? location}) {
    final nameController = TextEditingController(text: location?.name ?? '');
    final addressController =
        TextEditingController(text: location?.address ?? '');
    final isEditing = location != null;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Edit Location' : 'Add New Location'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                    labelText: 'Store Name (e.g., Main Branch)'),
              ),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Full Address'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    addressController.text.isNotEmpty) {
                  if (isEditing) {
                    _firestoreService.updateLocation(
                      locationId: location.id,
                      name: nameController.text,
                      address: addressController.text,
                    );
                  } else {
                    _firestoreService.addLocation(
                      name: nameController.text,
                      address: addressController.text,
                    );
                  }
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Manage Store Locations'),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showLocationDialog(),
          child: const Icon(Icons.add),
        ),
        body: SafeArea(
          child: _businessId == null
              ? const Center(child: Text('Not logged in.'))
              : StreamBuilder<List<LocationModel>>(
                  stream: _firestoreService.getLocations(_businessId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                          child: Text(
                              'No locations added yet. Tap + to add one.'));
                    }

                    final locations = snapshot.data!;

                    return ListView.builder(
                      itemCount: locations.length,
                      itemBuilder: (context, index) {
                        final location = locations[index];
                        return ListTile(
                          title: Text(location.name),
                          subtitle: Text(location.address),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                // Pass the whole LocationModel object
                                onPressed: () =>
                                    _showLocationDialog(location: location),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red),
                                // Use location.id from the model
                                onPressed: () => _firestoreService
                                    .deleteLocation(locationId: location.id),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
        ));
  }
}
