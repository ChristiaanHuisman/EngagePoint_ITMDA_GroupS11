// pages/full_screen_image_viewer.dart

import 'package:flutter/material.dart'; // CORRECT

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final String tag; // Unique tag for the Hero animation

  const FullScreenImageViewer({
    super.key,
    required this.imageUrl,
    required this.tag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white), // Makes the back button white
      ),
      body: Center(
        child: Hero(
          tag: tag, // This MUST match the tag on the previous screen
          child: InteractiveViewer( // Allows pinch-to-zoom and panning
            panEnabled: false,
            minScale: 1.0,
            maxScale: 4.0,
            child: Image.network(imageUrl),
          ),
        ),
      ),
    );
  }
}