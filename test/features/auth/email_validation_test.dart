import 'package:campus_care_app/core/utils/development_test_account.dart';
import 'package:campus_care_app/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ALU email validation', () {
    test('accepts normalized student and staff addresses', () {
      expect(
        Validators.validateAluEmail('  Person@AluStudent.com  '),
        isNull,
      );
      expect(
        Validators.validateAluEmail('person@alustaff.com'),
        isNull,
      );
      expect(
        Validators.normalizeEmail('  Person@AluStudent.com  '),
        'person@alustudent.com',
      );
    });

    test('requires a value and rejects malformed addresses', () {
      expect(Validators.validateAluEmail(null), 'Email address is required.');
      expect(Validators.validateAluEmail('  '), 'Email address is required.');
      for (final email in [
        'not-an-email',
        'two@@alustudent.com',
        '.student@alustudent.com',
        'student@alustudent.com.evil',
      ]) {
        expect(Validators.validateAluEmail(email), isNotNull, reason: email);
      }
    });

    test('rejects non-ALU domains and domain lookalikes', () {
      for (final email in [
        'person@gmail.com',
        'person@yahoo.com',
        'person@outlook.com',
        'person@sub.alustudent.com',
        'person@alustudent.com.example.org',
      ]) {
        expect(Validators.validateAluEmail(email), isNotNull, reason: email);
      }
    });

    test('keeps the development staff address out of ordinary registration', () {
      expect(
        Validators.validateAluEmail('staff.test@campuscare.dev'),
        isNotNull,
      );
    });

    test('accepts Staff Test for login only in emulator-enabled debug mode', () {
      expect(
        Validators.validateLoginEmail('staff.test@campuscare.dev'),
        isDevelopmentStaffTestEnabled ? isNull : isNotNull,
      );
      expect(
        Validators.validateLoginEmail('another@campuscare.dev'),
        isNotNull,
      );
    });

    test('rejects malformed addresses', () {
      for (final email in [
        'person',
        'person@@alustudent.com',
        '.person@alustudent.com',
        'person.@alustudent.com',
        'person..name@alustudent.com',
        'person@alustudent.com.',
      ]) {
        expect(Validators.validateAluEmail(email), isNotNull, reason: email);
      }
    });

    test('maps each exact domain to its allowed registration role', () {
      expect(
        Validators.roleForAluEmail('student@alustudent.com'),
        'student',
      );
      expect(
        Validators.roleForAluEmail('staff@alustaff.com'),
        'staff',
      );
      expect(Validators.roleForAluEmail('person@gmail.com'), isNull);
    });

    test('validates strong passwords and provides useful error messages', () {
      expect(Validators.validatePassword('CampusCare1!'), isNull);
      expect(Validators.validatePassword(null), 'Password is required.');
      expect(Validators.validatePassword('short'), contains('8 characters'));
      expect(
        Validators.validatePassword('lowercase1!'),
        contains('uppercase'),
      );
      expect(
        Validators.validatePassword('NOLOWERCASE1!'),
        contains('lowercase'),
      );
      expect(Validators.validatePassword('NoNumber!'), contains('number'));
      expect(Validators.validatePassword('NoSpecial1'), contains('special'));
      expect(
        Validators.validateConfirmPassword('Different1!', 'CampusCare1!'),
        'Passwords do not match.',
      );
    });
  });
}
