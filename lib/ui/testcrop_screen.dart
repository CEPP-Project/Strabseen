import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // For picking images
import 'dart:io'; // For using File

class TestCropScreen extends StatelessWidget {
  final List<XFile?> photos;

  const TestCropScreen({super.key, required this.photos});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cropped Photos'),
      ),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
        ),
        padding: const EdgeInsets.all(8.0),
        itemCount: photos.length,
        itemBuilder: (context, index) {
          final photo = photos[index];
          return photo != null
              ? Image.file(
            File(photo.path),
            fit: BoxFit.contain,
          )
              : const Center(child: Text('No Image'));
        },
      ),
    );
  }
}
