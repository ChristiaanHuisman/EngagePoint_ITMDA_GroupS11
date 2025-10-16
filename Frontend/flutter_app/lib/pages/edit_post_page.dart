import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class EditPostPage extends StatefulWidget {
  final QueryDocumentSnapshot post;

  const EditPostPage({super.key, required this.post});

  @override
  State<EditPostPage> createState() => _EditPostPageState();
}

class _EditPostPageState extends State<EditPostPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  
  bool _isLoading = false;
  File? _imageFile;
  String? _existingImageUrl;
  // ADDITION: Variable to hold aspect ratio of a new image
  double? _newImageAspectRatio; 

  @override
  void initState() {
    super.initState();
    final data = widget.post.data() as Map<String, dynamic>;
    _titleController = TextEditingController(text: data['title'] ?? '');
    _contentController = TextEditingController(text: data['content'] ?? '');
    _existingImageUrl = data['imageUrl'];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // ADDITION: Helper function to get the aspect ratio from an image file.
  Future<double> _getImageAspectRatio(File imageFile) async {
    final image = await decodeImageFromList(imageFile.readAsBytesSync());
    return image.width / image.height;
  }

  Future<void> _pickImage() async {
    final file = await _storageService.pickImage();
    if (file != null) {
      // ADDITION: Calculate aspect ratio when new image is picked
      _newImageAspectRatio = await _getImageAspectRatio(file);
      setState(() {
        _imageFile = file;
        _existingImageUrl = null;
      });
    }
  }

  Future<void> _updatePost() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageUrl = _existingImageUrl;
      double? imageAspectRatio = (widget.post.data() as Map<String, dynamic>)['imageAspectRatio'];
      
      if (_imageFile != null) {
        final path = 'post_images/${widget.post.id}.jpg';
        imageUrl = await _storageService.uploadFile(path, _imageFile!);
        // FIX: Use the aspect ratio we calculated when picking the image
        imageAspectRatio = _newImageAspectRatio;
      }
      
      await _firestoreService.updatePost(
        postId: widget.post.id,
        title: _titleController.text,
        content: _contentController.text,
        imageUrl: imageUrl,
        imageAspectRatio: imageAspectRatio, // FIX: Pass the aspect ratio
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post updated successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update post: $e')),
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
        title: const Text('Edit Post'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _updatePost,
            icon: const Icon(Icons.check),
          ),
        ],
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
                      ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(_imageFile!, fit: BoxFit.cover))
                      : (_existingImageUrl != null
                          ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(_existingImageUrl!, fit: BoxFit.cover))
                          : const Center(child: Text('Add an image'))),
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
            ],
          ),
        ),
      ),
    );
  }
}