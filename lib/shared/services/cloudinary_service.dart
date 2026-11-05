
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

// Identifies the type of image being uploaded.
enum CloudinaryImageType {
  incident,
  profile,
}

class CloudinaryService {
  static const String _cloudName = 'vbzq5ssu';

  static const int _maxFileSize = 2 * 1024 * 1024; // 2 MB

  static const Map<CloudinaryImageType, String> _uploadPresets = {
    CloudinaryImageType.incident: 'campuscare_incidents',
    CloudinaryImageType.profile: 'campuscare_profiles',
  };

  static const List<String> _allowedExtensions = [
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
  ];

  static const Duration _uploadTimeout = Duration(seconds: 90);

  // Uploads an incident photo or profile picture to Cloudinary.
  // 
  // Returns the secure Cloudinary URL.
  Future<String> uploadImage(
    File imageFile, {
    required CloudinaryImageType imageType,
  }) async {
    if (!await imageFile.exists()) {
      throw Exception('The selected image does not exist.');
    }

    // Validate image format.
    final extension = path.extension(imageFile.path).toLowerCase();

    if (!_allowedExtensions.contains(extension)) {
      throw Exception(
        'Unsupported image format. Please select JPG, JPEG, PNG or WEBP.',
      );
    }

    // Validate image size before uploading.
    final fileSize = await imageFile.length();

    if (fileSize == 0) {
      throw Exception('The selected image is empty.');
    }

    if (fileSize > _maxFileSize) {
      throw Exception(
        'Image size must not exceed 2 MB. '
        'Please choose a smaller image.',
      );
    }

    try {
      final uploadPreset = _uploadPresets[imageType];

      if (uploadPreset == null) {
        throw Exception('Invalid image upload type.');
      }

      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', uri);

      request.fields['upload_preset'] = uploadPreset;

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
        ),
      );

      final streamedResponse = await request.send().timeout(
        _uploadTimeout,
      );

      final response = await http.Response.fromStream(
        streamedResponse,
      ).timeout(_uploadTimeout);

      final dynamic responseData = jsonDecode(response.body);

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        if (responseData is Map<String, dynamic>) {
          final secureUrl = responseData['secure_url'];

          if (secureUrl is String && secureUrl.isNotEmpty) {
            return secureUrl;
          }
        }

        throw Exception(
          'Cloudinary did not return a valid image URL.',
        );
      }

      final errorMessage =
          responseData is Map &&
                  responseData['error'] is Map
              ? responseData['error']['message']
              : null;

      throw Exception(
        errorMessage?.toString() ??
            'Image upload failed. Please try again.',
      );
    } on TimeoutException {
      throw Exception(
        'Image upload timed out. Check your internet connection.',
      );
    } on SocketException {
      throw Exception(
        'No internet connection. Please try again.',
      );
    } on FormatException {
      throw Exception(
        'Cloudinary returned an invalid response.',
      );
    }
  }
}
