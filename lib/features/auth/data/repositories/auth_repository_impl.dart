
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(AuthRemoteDataSource dataSource)
      : _dataSource = dataSource;

  final AuthRemoteDataSource _dataSource;

  // Convert Firebase user and Firestore profile into AppUser.
  AppUser _mapUser(
    User user,
    Map<String, dynamic> profile,
  ) {
    return AppUser(
      id: user.uid,
      email: user.email ?? '',
      displayName: profile['name'] as String? ?? user.displayName,
      photoUrl: profile['photoUrl'] as String? ?? user.photoURL,
      emailVerified: user.emailVerified,
      role: profile['role'] as String? ?? 'unknown',
      accountStatus: profile['accountStatus'] as String? ?? 'pending',
    );
  }

  // Retrieve the authenticated user's Firestore profile.
  Future<AppUser> _getAuthenticatedUser(User? user) async {
    if (user == null) {
      throw StateError('Firebase did not return a user.');
    }

    final profile = await _dataSource.getCurrentUserProfile();

    if (profile == null) {
      throw StateError(
        'Your CampusCare profile was not found. Please register first.',
      );
    }

    return _mapUser(user, profile);
  }

  @override
  Future<AppUser> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required String selectedRole,
  }) async {
    final credential = await _dataSource.registerWithEmail(
      name: name,
      email: email,
      password: password,
      selectedRole: selectedRole,
    );

    return _getAuthenticatedUser(credential.user);
  }

  @override
  Future<AppUser?> signInWithGoogle({
    required String selectedRole,
  }) async {
    final credential = await _dataSource.signInWithGoogle(
      selectedRole: selectedRole,
    );

    if (credential?.user == null) {
      return null;
    }

    try {
      return await _getAuthenticatedUser(credential!.user);
    } catch (_) {
      await _dataSource.signOut();
      rethrow;
    }
  }

  @override
  Future<AppUser> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _dataSource.loginWithEmail(
      email: email,
      password: password,
    );

    try {
      return await _getAuthenticatedUser(credential.user);
    } catch (_) {
      await _dataSource.signOut();
      rethrow;
    }
  }

  @override
  Future<AppUser> loginWithGoogle() async {
    final credential = await _dataSource.loginWithGoogle();

    try {
      return await _getAuthenticatedUser(credential.user);
    } catch (_) {
      await _dataSource.signOut();
      rethrow;
    }
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final user = _dataSource.currentUser;

    if (user == null) {
      return null;
    }

    final profile = await _dataSource.getCurrentUserProfile();

    if (profile == null) {
      return null;
    }

    return _mapUser(user, profile);
  }

  @override
  Future<void> signOut() async {
    await _dataSource.signOut();
  }

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    await _dataSource.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> updateName({
    required String name,
  }) async {
    await _dataSource.updateName(name: name);
  }

  @override
  Future<void> updatePhotoUrl({
    required String? photoUrl,
  }) async {
    await _dataSource.updatePhotoUrl(photoUrl: photoUrl);
  }

  @override
  Future<void> changeEmail({
    required String newEmail,
    required String currentPassword,
  }) async {
    await _dataSource.changeEmail(
      newEmail: newEmail,
      currentPassword: currentPassword,
    );
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _dataSource.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}
