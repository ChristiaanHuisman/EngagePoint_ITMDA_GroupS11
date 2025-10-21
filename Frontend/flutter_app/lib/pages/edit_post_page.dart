import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class EditPostPage extends StatefulWidget {
  final PostModel post;

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
  Uint8List? _imageData;
  String? _existingImageUrl;

  String? _selectedTag;
  final List<String> _postTags = [
    'Promotion',
    'Sale',
    'Event',
    'New Stock',
    'Update'
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.post.title);
    _contentController = TextEditingController(text: widget.post.content);
    _existingImageUrl = widget.post.imageUrl;
    _selectedTag = widget.post.tag;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<double> _getImageAspectRatio(Uint8List imageData) async {
    final image = await decodeImageFromList(imageData);
    return image.width / image.height;
  }

  Future<void> _pickImage() async {
    final data = await _storageService.pickImageAsBytes();
    if (data != null) {
      setState(() {
        _imageData = data;
        _existingImageUrl = null; // Clear the existing image URL
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
      double? imageAspectRatio = widget.post.imageAspectRatio;

      if (_imageData != null) {
        final path = 'post_images/${widget.post.id}.jpg';
        imageUrl = await _storageService.uploadImageData(path, _imageData!);
        imageAspectRatio = await _getImageAspectRatio(_imageData!);
      }

      await _firestoreService.updatePost(
        postId: widget.post.id,
        title: _titleController.text,
        content: _contentController.text,
        imageUrl: imageUrl,
        imageAspectRatio: imageAspectRatio,
        tag: _selectedTag,
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
      body: SafeArea(
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _imageData != null
                        ? Image.memory(_imageData!,
                            fit: BoxFit.cover, width: double.infinity)
                        : (_existingImageUrl != null
                            ? Image.network(_existingImageUrl!,
                                fit: BoxFit.cover, width: double.infinity)
                            : const Center(
                                child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo_outlined,
                                      size: 40, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Change image (optional)'),
                                ],
                              ))),
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
            ],
          ),
        ),
      ),
    );
  }
}
