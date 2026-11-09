
import 'dart:io';

import 'package:image_picker/image_picker.dart';

import '../../core/utils/image_file_validation.dart';

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

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

    final fileSize = await file.length();
    final validationError = ImageFileValidation.validate(
      filePath: pickedFile.path,
      fileSize: fileSize,
    );
    if (validationError != null) {
      throw FormatException(validationError);
    }

    return file;
  }
}
