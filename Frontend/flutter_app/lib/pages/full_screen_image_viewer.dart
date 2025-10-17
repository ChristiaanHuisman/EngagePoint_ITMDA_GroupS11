import 'package:flutter/material.dart'; 

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final String tag; 

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
        iconTheme: const IconThemeData(color: Colors.white), 
      ),
      body: Center(
       child: InteractiveViewer(
    panEnabled: false,
    minScale: 1.0,
    maxScale: 4.0,
    child: Image.network(
      imageUrl,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child; 
        return const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        );
      },
    ),
  ),
      ),
    );
  }
}