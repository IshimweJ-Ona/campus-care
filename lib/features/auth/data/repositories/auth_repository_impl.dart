
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../../../../core/utils/validators.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(AuthRemoteDataSource dataSource)
      : _dataSource = dataSource;

  final AuthRemoteDataSource _dataSource;

  AppUser _mapUser(AuthenticatedUserSession session) {
    final profile = session.profile;
    final inferredRole = Validators.roleForAluEmail(session.email) ?? 'unknown';

    return AppUser(
      id: session.user.uid,
      email: session.email,
      displayName: profile?['name'] as String? ?? session.user.displayName,
      photoUrl: profile?['photoUrl'] as String? ?? session.user.photoURL,
      emailVerified: session.emailVerified,
      role: profile?['role'] as String? ?? inferredRole,
      accountStatus:
          profile?['accountStatus'] as String? ?? 'unverified',
    );
  }

  Future<AppUser> _getAuthenticatedUser({
    String? requiredNewAccountRole,
  }) async {
    final session = await _dataSource.loadAuthenticatedUser(
      requiredNewAccountRole: requiredNewAccountRole,
    );

    if (session == null) {
      throw StateError('Firebase did not return a user.');
    }

    return _mapUser(session);
  }

  @override
  Future<void> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required String selectedRole,
  }) async {
    await _dataSource.registerWithEmail(
      name: name,
      email: email,
      password: password,
      selectedRole: selectedRole,
    );
  }

  @override
  Future<AppUser?> signInWithGoogle({
    required String selectedRole,
  }) async {
    final credential = await _dataSource.signInWithGoogle();

    if (credential?.user == null) {
      return null;
    }

    try {
      return await _getAuthenticatedUser(
        requiredNewAccountRole: selectedRole,
      );
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
    await _dataSource.loginWithEmail(
      email: email,
      password: password,
    );

    try {
      return await _getAuthenticatedUser();
    } catch (_) {
      await _dataSource.signOut();
      rethrow;
    }
  }

  @override
  Future<AppUser> loginWithGoogle() async {
    await _dataSource.loginWithGoogle();

    try {
      return await _getAuthenticatedUser();
    } catch (_) {
      await _dataSource.signOut();
      rethrow;
    }
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final session = await _dataSource.loadAuthenticatedUser();
    return session == null ? null : _mapUser(session);
  }

  @override
  Future<void> resendVerificationEmail() {
    return _dataSource.resendVerificationEmail();
  }

  @override
  Future<AppUser> completeEmailVerification() async {
    final session = await _dataSource.loadAuthenticatedUser();
    if (session == null) {
      throw StateError('Sign in before completing email verification.');
    }
    if (!session.emailVerified || session.profile == null) {
      throw StateError(
        'Your email is not verified yet. Open the link we sent you and try again.',
      );
    }

    return _mapUser(session);
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
