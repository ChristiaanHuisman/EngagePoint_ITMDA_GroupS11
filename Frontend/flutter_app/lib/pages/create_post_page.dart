import 'dart:io';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isLoading = false;
  File? _imageFile;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
  
  // Method to handle picking an image from the gallery.
  Future<void> _pickImage() async {
    final file = await _storageService.pickImage();
    if (file != null) {
      setState(() {
        _imageFile = file;
      });
    }
  }

  // ADDITION: Helper function to get the aspect ratio from an image file.
  Future<double> _getImageAspectRatio(File imageFile) async {
    final image = await decodeImageFromList(imageFile.readAsBytesSync());
    return image.width / image.height;
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageUrl;
      double? imageAspectRatio; // ADDITION: Variable for aspect ratio

      if (_imageFile != null) {
        final path = 'post_images/${DateTime.now().millisecondsSinceEpoch}.jpg';
        imageUrl = await _storageService.uploadFile(path, _imageFile!);
        // ADDITION: Calculate aspect ratio before submitting
        imageAspectRatio = await _getImageAspectRatio(_imageFile!);
      }
      
      await _firestoreService.createPost(
        title: _titleController.text,
        content: _contentController.text,
        imageUrl: imageUrl,
        imageAspectRatio: imageAspectRatio, // FIX: Pass the aspect ratio
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post created successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create post: $e')),
        );
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
        title: const Text('Create New Post'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: InkWell(
                  onTap: _pickImage,
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(_imageFile!, fit: BoxFit.cover, width: double.infinity),
                        )
                      : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Add an image (optional)'),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Post Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Post Content',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 8,
                validator: (value) => value == null || value.isEmpty ? 'Please enter content' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitPost,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Text('Publish Post'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}