import 'package:cloud_firestore/cloud_firestore.dart';

class LocationModel {
  final String id;
  final String name;
  final String address;

  LocationModel({
    required this.id,
    required this.name,
    required this.address,
  });

  factory LocationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return LocationModel(
      id: doc.id,
      name: data['name'] ?? 'Unnamed Location',
      address: data['address'] ?? 'No Address Provided',
    );
  }
}