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
  });
}
