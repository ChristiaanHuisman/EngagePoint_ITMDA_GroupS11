import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart'; // Required for Uint8List
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

  /// Uploads raw image data  to Firebase Storage.
  /// This works on both mobile and web.
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
}
