import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cloudinary_service.dart';
import 'image_picker_service.dart';

final cloudinaryServiceProvider = Provider<CloudinaryService>((ref) {
  return CloudinaryService();
});

final imagePickerServiceProvider = Provider<ImagePickerService>((ref) {
  return ImagePickerService();
});
