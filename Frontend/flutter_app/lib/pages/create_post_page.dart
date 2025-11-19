import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../services/moderation_service.dart';

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

  bool _isScheduled = false;
  DateTime? _scheduledTime;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // Method to handle picking an image from the gallery
  Future<void> _pickImage() async {
    final data = await _storageService.pickImageAsBytes();
    if (data != null) {
      setState(() {
        _imageData = data;
      });
    }
  }

  Future<void> _pickScheduleDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _scheduledTime ?? DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_scheduledTime ?? DateTime.now().add(const Duration(hours: 1))),
      );

      if (pickedTime != null) {
        setState(() {
          _scheduledTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  // Helper function to get the aspect ratio from image data
  Future<double> _getImageAspectRatio(Uint8List imageData) async {
    final image = await decodeImageFromList(imageData);
    return image.width / image.height;
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check schedule time before upload
    if (_isScheduled && _scheduledTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a schedule time'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageUrl;
      double? imageAspectRatio;

      if (_imageData != null) {
        final path = 'post_images/${DateTime.now().millisecondsSinceEpoch}.jpg';
        imageUrl = await _storageService.uploadImageData(path, _imageData!);
        imageAspectRatio = await _getImageAspectRatio(_imageData!);
      }

      // MODERATION INJECTION START
      final ModerationService moderationService = ModerationService();

      try {
        // Moderate text content
        final ModerationResult textResult =
            await moderationService.moderateText(_contentController.text);
        
        if (!textResult.approved) {
          final reason = textResult.reason ?? 'Content not allowed';
          throw Exception('Post rejected: $reason');
        }

        // Moderate image 
        if (imageUrl != null) {
          final ModerationResult imageResult =
              await moderationService.moderateImage(imageUrl);
          
          if (!imageResult.approved) {
            try {
              await _storageService.deleteByUrl(imageUrl);
            } catch (_) {
           }
            final reason = imageResult.reason ?? 'Image not allowed';
            throw Exception('Image rejected: $reason');
          }
        }
      } on ModerationException catch (me) {
        // Convert moderation-specific error into a user-visible exception
        throw Exception('Moderation failed: ${me.message}');
      }
      // MODERATION INJECTION END

      // --- CONSOLIDATED POST CREATION ---
      await _firestoreService.createPost(
        title: _titleController.text,
        content: _contentController.text,
        imageUrl: imageUrl,
        imageAspectRatio: imageAspectRatio,
        tag: _selectedTag,
        scheduledTime: _isScheduled ? _scheduledTime : null,
      );

      if (mounted) {
        final successMessage = _isScheduled
            ? 'Post scheduled for ${DateFormat.yMd().add_jm().format(_scheduledTime!)}'
            : 'Post created successfully!';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage)),
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
                const SizedBox(height: 16),
                const Divider(),
                SwitchListTile(
                  title: const Text('Schedule Post'),
                  subtitle: const Text('Post this at a future date and time'),
                  value: _isScheduled,
                  onChanged: (bool value) {
                    setState(() {
                      _isScheduled = value;
                      if (!_isScheduled) {
                        _scheduledTime = null;
                      }
                    });
                  },
                  activeThumbColor: Theme.of(context).colorScheme.primary,
                ),
                Visibility(
                  visible: _isScheduled,
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Publish Time'),
                    subtitle: Text(
                      _scheduledTime == null
                          ? 'Select Date & Time'
                          // Format the date/time
                          : DateFormat.yMd().add_jm().format(_scheduledTime!),
                    ),
                    onTap: _pickScheduleDateTime,
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  ),
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
