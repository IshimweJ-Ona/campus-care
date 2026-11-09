import 'package:flutter/foundation.dart';

const developmentStaffTestEmail = 'staff.test@campuscare.dev';

const _useFirebaseEmulators = bool.fromEnvironment(
  'USE_FIREBASE_EMULATORS',
  defaultValue: false,
);

bool get isDevelopmentStaffTestEnabled =>
    kDebugMode && _useFirebaseEmulators;

bool isDevelopmentStaffTestEmail(String? email) {
  return isDevelopmentStaffTestEnabled &&
      email?.trim().toLowerCase() == developmentStaffTestEmail;
}
