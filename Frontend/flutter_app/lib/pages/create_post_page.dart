import 'package:flutter/foundation.dart';
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
  final _formKey = GlobalKey<FormState>(); // This key needs a Form widget
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isLoading = false;

  // Use Uint8List to store image data in memory, not File.
  Uint8List? _imageData;

  String? _selectedTag;
  final List<String> _postTags = [
    'Promotion',
    'Sale',
    'Event',
    'New Stock',
    'Update'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // Method to handle picking an image from the gallery.
  Future<void> _pickImage() async {
    // Use the new service method that returns bytes.
    final data = await _storageService.pickImageAsBytes();
    if (data != null) {
      setState(() {
        _imageData = data;
      });
    }
  }

  // Helper function to get the aspect ratio from image data.
  Future<double> _getImageAspectRatio(Uint8List imageData) async {
    final image = await decodeImageFromList(imageData);
    return image.width / image.height;
  }

  Future<void> _submitPost() async {
    // This line will now work because the key is attached to a Form.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageUrl;
      double? imageAspectRatio;

      // Check for _imageData instead of _imageFile.
      if (_imageData != null) {
        final path = 'post_images/${DateTime.now().millisecondsSinceEpoch}.jpg';
        // Use the new upload method.
        imageUrl = await _storageService.uploadImageData(path, _imageData!);
        // Calculate aspect ratio from the image data.
        imageAspectRatio = await _getImageAspectRatio(_imageData!);
      }

      await _firestoreService.createPost(
        title: _titleController.text,
        content: _contentController.text,
        imageUrl: imageUrl,
        imageAspectRatio: imageAspectRatio,
        tag: _selectedTag,
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
      body: SafeArea(
        child: Form(
          key: _formKey, // Assign the key here
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
                    // Use Image.memory to display the image from bytes.
                    child: _imageData != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(_imageData!,
                                fit: BoxFit.cover, width: double.infinity),
                          )
                        : const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_outlined,
                                    size: 40, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('Add an image (optional)'),
                              ],
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                DropdownButtonFormField<String>(
                  initialValue: _selectedTag,
                  decoration: const InputDecoration(
                    labelText: 'Post Category / Tag',
                    border: OutlineInputBorder(),
                  ),
                  hint: const Text('Select a tag (optional)'),
                  items: _postTags.map((String tag) {
                    return DropdownMenuItem<String>(
                      value: tag,
                      child: Text(tag),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedTag = newValue;
                    });
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Post Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter a title'
                      : null,
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
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter content'
                      : null,
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
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text('Publish Post'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}