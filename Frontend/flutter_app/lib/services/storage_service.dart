import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  Future<Uint8List?> pickImageAsBytes() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      return await image.readAsBytes();
    }
    return null;
  }

  // Uploads raw image data to Firebase Storage.
  Future<String> uploadImageData(String path, Uint8List data) async {
    try {
      final ref = _storage.ref().child(path);

      final metadata = SettableMetadata(contentType: 'image/jpeg');
      final uploadTask = await ref.putData(data, metadata);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint("Error uploading image data: $e");
      rethrow;
    }
  }

  /// Deletes a file from Firebase Storage using its download URL.
  /// This uses `refFromURL` which supports firebase storage download URLs.
  /// It will quietly ignore "not found" errors and print failures for debugging.
  Future<void> deleteByUrl(String imageUrl) async {
    try {
      // refFromURL throws if the URL cannot be parsed as a Storage reference.
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      debugPrint(' Image deleted successfully: $imageUrl');
    } on FirebaseException catch (e) {
      // If the file doesn't exist or permission denied, FirebaseException is thrown.
      // We swallow "object not found" errors (code 'object-not-found') but log others.
      if (e.code == 'object-not-found' || e.code == '404') {
        debugPrint('Delete skipped — object not found: $imageUrl');
      } else {
        debugPrint('Firebase exception deleting image: ${e.code} - ${e.message}');
      }
    } catch (e) {
      debugPrint('Failed to delete image: $e');
    }
  }
}
