import 'package:path/path.dart' as path;

class ImageFileValidation {
  ImageFileValidation._();

  static const maxFileSize = 2 * 1024 * 1024;
  static const allowedExtensions = {'.jpg', '.jpeg', '.png', '.webp'};

  static String? validate({
    required String filePath,
    required int fileSize,
  }) {
    final extension = path.extension(filePath).toLowerCase();
    if (!allowedExtensions.contains(extension)) {
      return 'Please select a JPG, JPEG, PNG or WEBP image.';
    }
    if (fileSize <= 0) {
      return 'The selected image is empty.';
    }
    if (fileSize > maxFileSize) {
      return 'Image size must not exceed 2 MB. Please select a smaller image.';
    }
    return null;
  }
}
