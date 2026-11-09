import 'package:campus_care_app/core/utils/auth_email_verification.dart';
import 'package:campus_care_app/features/auth/domain/entities/app_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppUser permissions', () {
    test('active students can access incidents, not staff features', () {
      const student = AppUser(
        id: 'student',
        email: 'student@alustudent.com',
        emailVerified: true,
        role: 'student',
        accountStatus: 'active',
      );
      expect(student.isActiveStudent, isTrue);
      expect(student.canAccessIncidents, isTrue);
      expect(student.canUseStaffFeatures, isFalse);
    });

    test('pending staff cannot access incident or staff functionality', () {
      const pendingStaff = AppUser(
        id: 'pending',
        email: 'staff@alustaff.com',
        emailVerified: true,
        role: 'pending_staff',
        accountStatus: 'pending',
      );
      expect(pendingStaff.canAccessIncidents, isFalse);
      expect(pendingStaff.canUseStaffFeatures, isFalse);
    });

    test('only active staff can use staff features', () {
      const staff = AppUser(
        id: 'staff',
        email: 'staff@alustaff.com',
        emailVerified: true,
        role: 'staff',
        accountStatus: 'active',
      );
      const inactiveStaff = AppUser(
        id: 'inactive',
        email: 'staff@alustaff.com',
        emailVerified: true,
        role: 'staff',
        accountStatus: 'disabled',
      );
      expect(staff.canUseStaffFeatures, isTrue);
      expect(staff.canAccessIncidents, isTrue);
      expect(inactiveStaff.canUseStaffFeatures, isFalse);
      expect(
        const AppUser(
          id: 'unverified',
          email: 'staff@alustaff.com',
          role: 'staff',
          accountStatus: 'active',
        ).canUseStaffFeatures,
        isFalse,
      );
    });
  });

  group('email verification claims', () {
    bool verified({
      bool userVerified = true,
      bool tokenVerified = true,
      String? userEmail = 'student@alustudent.com',
      String? tokenEmail = 'student@alustudent.com',
    }) {
      return AuthEmailVerification.isVerified(
        authUserVerified: userVerified,
        tokenVerified: tokenVerified,
        authenticatedEmail: userEmail,
        tokenEmail: tokenEmail,
      );
    }

    test('requires user and token verification with matching email claims', () {
      expect(verified(), isTrue);
      expect(verified(userVerified: false), isFalse);
      expect(verified(tokenVerified: false), isFalse);
      expect(verified(tokenEmail: 'someone-else@alustudent.com'), isFalse);
      expect(verified(userEmail: null), isFalse);
    });
  });
}