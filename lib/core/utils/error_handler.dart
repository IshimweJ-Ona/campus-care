
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class ErrorHandler {
  ErrorHandler._();

  static String getMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'An account already exists with this email.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'weak-password':
          return 'Your password is too weak. Use a stronger password.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'The email or password is incorrect.';
        case 'user-disabled':
          return 'This account has been disabled. Contact support.';
        case 'network-request-failed':
          return 'Network error. Check your internet connection.';
        case 'operation-not-allowed':
          return 'This sign-in method is not enabled in Firebase.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        case 'account-exists-with-different-credential':
          return 'An account already exists with another sign-in method.';
        default:
          return 'Authentication failed. Please try again.';
      }
    }

    if (error is FirebaseException) {
      return 'A Firebase service error occurred. Please try again.';
    }

    if (error is PlatformException) {
      return error.message ?? 'The operation could not be completed.';
    }

    if (error is StateError) {
      return error.message.toString();
    }

    return 'Something went wrong. Please try again.';
  }
}
