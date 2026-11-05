
import '../entities/app_user.dart';

abstract class AuthRepository {
  Future<AppUser> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required String selectedRole,
  });

  Future<AppUser?> signInWithGoogle({
    required String selectedRole,
  });

  Future<AppUser> loginWithEmail({
    required String email,
    required String password,
  });

  Future<AppUser> loginWithGoogle();

  Future<AppUser?> getCurrentUser();

  Future<void> signOut();

  Future<void> sendPasswordResetEmail({
    required String email,
  });

  // Update the user's full name.
  Future<void> updateName({
    required String name,
  });

  // Update or remove the user's profile picture URL.
  Future<void> updatePhotoUrl({
    required String? photoUrl,
  });

  // Request an email change and send a verification link.
  Future<void> changeEmail({
    required String newEmail,
    required String currentPassword,
  });

  // Change the user's password.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}
