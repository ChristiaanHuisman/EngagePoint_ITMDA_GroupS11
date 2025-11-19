import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/models/user_model.dart'; // Make sure this path is correct
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

// For using the business verification microservice
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  late final TextEditingController _websiteController;

  Uint8List? _imageData;
  String? _existingImageUrl;
  bool _isLoading = false;

  // For the business verification microservice part
  String? _verificationMessage;
  bool _hasRequestedVerification = false;
  bool _isVerificationLocked = false;
  String? _lockedMessage;
  bool _isInitialCheck = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _descriptionController =
        TextEditingController(text: widget.user.description ?? '');
    _businessTypeController =
        TextEditingController(text: widget.user.businessType ?? '');
        
    _websiteController = TextEditingController(text: widget.user.website ?? '');
    
    _existingImageUrl = widget.user.photoUrl;

    // For locking the business verification microservice
    _checkVerificationStatus();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _businessTypeController.dispose();
    
    _websiteController.dispose();
    
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
        
        dataToUpdate['website'] = _websiteController.text.trim();
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

  // Method for checking the user verification status
  Future<void> _checkVerificationStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final status = doc.data()?['verificationStatus'] as String?;

        if (status != null) {
          // Only update lock message if this check runs on init
          if (_isInitialCheck) {
            setState(() {
              switch (status) {
                case 'pendingAdmin':
                  _isVerificationLocked = true;
                  _lockedMessage =
                  'Your business verification request is pending admin approval.';
                  break;
                case 'pendingEmail':
                  _isVerificationLocked = true;
                  _lockedMessage =
                  'Your business verification request is pending your email verification.';
                  break;
                case 'accepted':
                  _isVerificationLocked = true;
                  _lockedMessage =
                  'Your business has already been verified.';
                  break;
              }
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking verification status: $e');
    } finally {
      // After first check, mark as no longer initial
      _isInitialCheck = false;
    }
  }

  // Method for calling the business verification microservice
  Future<void> _requestBusinessVerification() async {
    const String apiUrl =
        // HTTPS request for Cloud Run hosted business verification service
        'https://business-verification-service-570976278139.africa-south1.run.app/api/BusinessVerification/request-business-verification';

    setState(() {
      _isLoading = true;
      _verificationMessage = null; // Clear previous message
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user?.getIdToken();
      final authToken = 'Bearer $idToken';

      // Apply a 60 second timeout to the request
      final response = await http
          .get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': authToken,
          'Content-Type': 'application/json',
        },
      )
          .timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw TimeoutException('Connection timed out');
        },
      );

      final data = jsonDecode(response.body);
      final message = data['message'] ?? 'Verification request successful.';

      setState(() {
        _verificationMessage = message;
        if (response.statusCode == 200) {
          _hasRequestedVerification = true;
        }
      });

      // After the API call, check the verification status again
      await Future.delayed(const Duration(seconds: 2));
      await _checkVerificationStatus();

    } on TimeoutException {
      setState(() {
        _verificationMessage =
        'Network issue: The request took too long. Please check your connection and try again later.';
      });
    } catch (e) {
      setState(() {
        _verificationMessage = 'Request failed: $e';
      });
    } finally {
      setState(() => _isLoading = false);
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
                  
                  // Business-Only Fields
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

                  if (widget.user.isBusiness)
                    TextFormField(
                      controller: _websiteController,
                      decoration: const InputDecoration(
                        labelText: 'Website',
                        hintText: 'https://www.yourbusiness.com',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.language),
                      ),
                      keyboardType: TextInputType.url,

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

                  // Button for business verification request
                  if (widget.user.isBusiness) ...[
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: (_isLoading || _hasRequestedVerification || _isVerificationLocked)
                          ? null
                          : _requestBusinessVerification,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: (_hasRequestedVerification || _isVerificationLocked)
                            ? Colors.grey
                            : Theme.of(context).colorScheme.primaryContainer,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.verified),
                          SizedBox(width: 8),
                          Text('Request Business Verification'),
                        ],
                      ),
                    ),
                  ],

                  // Message display of business verification request
                  if (_lockedMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _lockedMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ] else if (_verificationMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _verificationMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                  // End Business-Only Fields
                ],
              ),
            ),
          ),
        ));
  }
}