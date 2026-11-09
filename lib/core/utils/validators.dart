
import 'development_test_account.dart';

class Validators {
  Validators._();

  static final RegExp _emailPattern = RegExp(
    r"^[a-z0-9!#$%&'*+/=?^_`{|}~-]+"
    r"(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*"
    r"@(alustudent\.com|alustaff\.com)$",
  );

  static String normalizeEmail(String email) => email.trim().toLowerCase();

  static String? roleForAluEmail(String? value) {
    if (value == null) return null;

    final email = normalizeEmail(value);
    if (!_emailPattern.hasMatch(email) || email.length > 254) {
      return null;
    }

    return email.endsWith('@alustudent.com') ? 'student' : 'staff';
  }

  static String? validateAluEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required.';
    }

    final email = normalizeEmail(value);
    if (email.length > 254) {
      return 'Email address is too long.';
    }

    if (!_emailPattern.hasMatch(email)) {
      return 'Enter a valid @alustudent.com or @alustaff.com email address.';
    }

    if (email.split('@').first.length > 64) {
      return 'Email address is too long.';
    }

    return null;
  }

  // Full Name
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required.';
    }

    final name = value.trim();

    if (name.length < 4) {
      return 'Name must be at least 4 characters.';
    }

    if (name.length > 50) {
      return 'Name cannot exceed 50 characters.';
    }

    if (!RegExp(r"^[a-zA-ZÀ-ÿ\s'-]+$").hasMatch(name)) {
      return 'Name contains invalid characters.';
    }

    return null;
  }

  // Email
  static String? validateEmail(String? value) {
    return validateAluEmail(value);
  }

  static String? validateLoginEmail(String? value) {
    if (validateAluEmail(value) == null ||
        isDevelopmentStaffTestEmail(value)) {
      return null;
    }

    return validateAluEmail(value);
  }

  // Password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters.';
    }

    if (value.length > 128) {
      return 'Password is too long.';
    }

    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Include at least one uppercase letter.';
    }

    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Include at least one lowercase letter.';
    }

    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Include at least one number.';
    }

    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Include at least one special character.';
    }

    return null;
  }

  // Confirm Password
  static String? validateConfirmPassword(
    String? value,
    String password,
  ) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password.';
    }

    if (value != password) {
      return 'Passwords do not match.';
    }

    return null;
  }

  // Phone Number
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required.';
    }

    // Remove spaces, hyphens, and parentheses.
    final phone = value.replaceAll(RegExp(r'[\s()-]'), '');

    if (!RegExp(r'^\+?[1-9]\d{7,14}$').hasMatch(phone)) {
      return 'Enter a valid phone number.';
    }

    return null;
  }

  // Username
  static String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username is required.';
    }

    final username = value.trim();

    if (username.length < 3 || username.length > 20) {
      return 'Username must be 3-20 characters.';
    }

    if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(username)) {
      return 'Only letters, numbers, . and _ are allowed.';
    }

    return null;
  }
}
