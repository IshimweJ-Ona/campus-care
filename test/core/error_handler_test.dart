import 'package:campus_care_app/core/utils/error_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ErrorHandler', () {
    test('maps common auth failures to actionable messages', () {
      expect(
        ErrorHandler.getMessage(
          FirebaseAuthException(code: 'wrong-password'),
        ),
        'The email or password is incorrect.',
      );
      expect(
        ErrorHandler.getMessage(
          FirebaseAuthException(code: 'network-request-failed'),
        ),
        'Network error. Check your internet connection.',
      );
      expect(
        ErrorHandler.getMessage(
          FirebaseAuthException(code: 'unrecognized-code'),
        ),
        'Authentication failed. Please try again.',
      );
    });

    test('handles Firebase, platform, state, and unknown errors', () {
      expect(
        ErrorHandler.getMessage(
          FirebaseException(plugin: 'firestore'),
        ),
        'A Firebase service error occurred. Please try again.',
      );
      expect(
        ErrorHandler.getMessage(
          PlatformException(code: 'platform', message: 'Camera unavailable'),
        ),
        'Camera unavailable',
      );
      expect(
        ErrorHandler.getMessage(StateError('Profile unavailable')),
        'Profile unavailable',
      );
      expect(
        ErrorHandler.getMessage(Exception('unexpected')),
        'Something went wrong. Please try again.',
      );
    });
  });
}
