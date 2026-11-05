
import 'dart:io';

import 'package:image_picker/image_picker.dart';

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  static const int _maxFileSize = 2 * 1024 * 1024;

  static const List<String> _allowedExtensions = [
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
  ];

  /// Select an image from the device gallery.
  Future<File?> pickFromGallery() async {
    return _pickImage(ImageSource.gallery);
  }

  /// Capture an image using the device camera.
  Future<File?> takePhoto() async {
    return _pickImage(ImageSource.camera);
  }

  /// Shared image selection and validation.
  Future<File?> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1600,
      maxHeight: 1600,
    );

    if (pickedFile == null) {
      return null;
    }

    final file = File(pickedFile.path);

    if (!await file.exists()) {
      throw Exception('The selected image could not be found.');
    }

    final extension =
        pickedFile.path.split('.').last.toLowerCase();

    if (!_allowedExtensions.contains('.$extension')) {
      throw Exception(
        'Please select a JPG, JPEG, PNG or WEBP image.',
      );
    }

    final fileSize = await file.length();

    if (fileSize == 0) {
      throw Exception('The selected image is empty.');
    }

    if (fileSize > _maxFileSize) {
      throw Exception(
        'Image size must not exceed 2 MB. '
        'Please select a smaller image.',
      );
    }

    return file;
  }
}
