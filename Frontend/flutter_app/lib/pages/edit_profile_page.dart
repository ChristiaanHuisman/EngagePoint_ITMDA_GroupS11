import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class EditProfilePage extends StatefulWidget {
  final UserModel user;

  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _businessTypeController;

  Uint8List? _imageData;
  String? _existingImageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _descriptionController =
        TextEditingController(text: widget.user.description ?? '');
    _businessTypeController =
        TextEditingController(text: widget.user.businessType ?? '');
    _existingImageUrl = widget.user.photoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _businessTypeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final data = await _storageService.pickImageAsBytes();
    if (data != null) {
      setState(() {
        _imageData = data;
        _existingImageUrl = null; 
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? newPhotoUrl = _existingImageUrl;

      if (_imageData != null) {
        final path = 'profile_pictures/${widget.user.uid}';
        newPhotoUrl = await _storageService.uploadImageData(path, _imageData!);
      }

      final Map<String, dynamic> dataToUpdate = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'photoUrl': newPhotoUrl, 
      };

      if (widget.user.isBusiness) {
        dataToUpdate['businessType'] = _businessTypeController.text.trim();
      }

      await _firestoreService.updateUserProfile(widget.user.uid, dataToUpdate);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update profile: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Edit Profile'),
          actions: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: Center(
                    child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white))),
              )
            else
              IconButton(
                onPressed: _saveProfile,
                icon: const Icon(Icons.check),
              ),
          ],
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: _imageData != null
                          ? MemoryImage(_imageData!)
                          : (_existingImageUrl != null
                              ? NetworkImage(_existingImageUrl!)
                              : null) as ImageProvider?,
                      child: _imageData == null && _existingImageUrl == null
                          ? Icon(
                              widget.user.isBusiness
                                  ? Icons.store
                                  : Icons.person,
                              size: 60)
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
                      labelText: widget.user.isBusiness
                          ? 'Business Name'
                          : 'Full Name',
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Please enter a name'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  if (widget.user.isBusiness)
                    TextFormField(
                      controller: _businessTypeController,
                      decoration: const InputDecoration(
                        labelText: 'Business Type',
                        hintText: 'e.g., Restaurant, Retail, Cafe',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  if (widget.user.isBusiness) const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Profile Description',
                      hintText: widget.user.isBusiness
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
        ));
  }
}
