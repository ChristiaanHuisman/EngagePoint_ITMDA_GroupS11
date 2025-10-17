import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_app/models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String userId;

  const EditProfilePage({super.key, required this.userData, required this.userId, required UserModel user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  //  Controller for the new text field
  late final TextEditingController _businessTypeController;
  File? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData['name'] ?? '');
    _descriptionController = TextEditingController(text: widget.userData['description'] ?? '');
    // Initialize the controller with existing data
    _businessTypeController = TextEditingController(text: widget.userData['businessType'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    //  Dispose of the new controller
    _businessTypeController.dispose();
    super.dispose();
  }
  
  Future<void> _pickImage() async {
    final file = await _storageService.pickImage();
    if (file != null) {
      setState(() {
        _imageFile = file;
      });
    }
  }
  
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? newPhotoUrl;
      
      if (_imageFile != null) {
        final path = 'profile_pictures/${widget.userId}';
        newPhotoUrl = await _storageService.uploadFile(path, _imageFile!);
      }
      
      final Map<String, dynamic> dataToUpdate = {
        'name': _nameController.text.trim(),
        'searchName': _nameController.text.trim().toLowerCase(),
        'description': _descriptionController.text.trim(),
        // Get the business type from the text controller
        'businessType': _businessTypeController.text.trim(),
      };
      
      if (newPhotoUrl != null) {
        dataToUpdate['photoUrl'] = newPhotoUrl;
      }

      await _firestoreService.updateUserProfile(widget.userId, dataToUpdate);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String role = widget.userData['role'] ?? 'customer';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))),
            )
          else
            IconButton(
              onPressed: _saveProfile,
              icon: const Icon(Icons.check),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: _imageFile != null
                      ? FileImage(_imageFile!)
                      : (widget.userData['photoUrl'] != null
                          ? NetworkImage(widget.userData['photoUrl'])
                          : null) as ImageProvider?,
                  child: _imageFile == null && widget.userData['photoUrl'] == null
                      ? Icon(role == 'business' ? Icons.store : Icons.person, size: 60)
                      : null,
                ),
              ),
              TextButton(
                onPressed: _pickImage,
                child: const Text('Change Profile Picture'),
              ),
              
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: role == 'business' ? 'Business Name' : 'Full Name',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),
              // Show this field only for business users
              if (role == 'business')
                TextFormField(
                  controller: _businessTypeController,
                  decoration: const InputDecoration(
                    labelText: 'Business Type',
                    hintText: 'e.g., Restaurant, Retail, Cafe',
                    border: OutlineInputBorder(),
                  ),
                ),
              
              if (role == 'business')
                const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Profile Description',
                  hintText: role == 'business'
                      ? 'Tell customers about your business...'
                      : 'A little bit about yourself...',
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
              ),
              
            ],
          ),
        ),
      ),
    );
  }
}
