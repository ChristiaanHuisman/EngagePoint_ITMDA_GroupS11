import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart'; // <-- FIX APPLIED: Import for debugPrint

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Lets the user pick an image from their gallery.
  // Returns a File object or null if the user cancels.
  Future<File?> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  // Uploads a file to a specific path in Firebase Cloud Storage
  // and returns the public download URL.
  Future<String> uploadFile(String path, File file) async {
    try {
      Reference storageRef = _storage.ref().child(path);

      UploadTask uploadTask = storageRef.putFile(file);
      
      TaskSnapshot snapshot = await uploadTask;
      
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      
      
      debugPrint("Error uploading file: $e");
      
      rethrow;
    }
  }
}

