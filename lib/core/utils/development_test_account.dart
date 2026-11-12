import 'package:flutter/foundation.dart';

const developmentStaffTestEmail = 'staff.test@campuscare.dev';

// One verified personal account authorized for the production demonstration.
// Remove this exception after the demonstration is complete.
const productionDemoStaffEmail = 'livishjonathan@gmail.com';

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
