
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/utils/error_handler.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

final authRemoteDataSourceProvider =
    Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(authRemoteDataSourceProvider),
  );
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(
    ref.watch(authRepositoryProvider),
  );
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController(this._repository)
      : super(const AsyncData(null));

  final AuthRepository _repository;

  // Executes user-triggered authentication operations.
  Future<T> _execute<T>(
    Future<T> Function() action,
  ) async {
    state = const AsyncLoading();

    try {
      final result = await action();

      state = const AsyncData(null);

      return result;
    } catch (error, stackTrace) {
      final message = ErrorHandler.getMessage(error);

      state = AsyncError(message, stackTrace);

      throw Exception(message);
    }
  }

  Future<AppUser> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required String selectedRole,
  }) {
    return _execute(
      () => _repository.registerWithEmail(
        name: name,
        email: email,
        password: password,
        selectedRole: selectedRole,
      ),
    );
  }

  Future<AppUser?> signInWithGoogle({
    required String selectedRole,
  }) {
    return _execute(
      () => _repository.signInWithGoogle(
        selectedRole: selectedRole,
      ),
    );
  }

  Future<AppUser> loginWithEmail({
    required String email,
    required String password,
  }) {
    return _execute(
      () => _repository.loginWithEmail(
        email: email,
        password: password,
      ),
    );
  }

  Future<AppUser> loginWithGoogle() {
    return _execute(
      () => _repository.loginWithGoogle(),
    );
  }

  // Read the current user without modifying provider state.
  Future<AppUser?> getCurrentUser() async {
    try {
      return await _repository.getCurrentUser();
    } catch (error) {
      throw Exception(ErrorHandler.getMessage(error));
    }
  }

  Future<void> signOut() {
    return _execute(
      () => _repository.signOut(),
    );
  }

  Future<void> sendPasswordResetEmail({
    required String email,
  }) {
    return _execute(
      () => _repository.sendPasswordResetEmail(
        email: email,
      ),
    );
  }

  // Update the user's full name.
  Future<void> updateName({
    required String name,
  }) {
    return _execute(
      () => _repository.updateName(name: name),
    );
  }

  // Update or remove the user's profile picture.
  Future<void> updatePhotoUrl({
    required String? photoUrl,
  }) {
    return _execute(
      () => _repository.updatePhotoUrl(photoUrl: photoUrl),
    );
  }

  // Request an email change.
  Future<void> changeEmail({
    required String newEmail,
    required String currentPassword,
  }) {
    return _execute(
      () => _repository.changeEmail(
        newEmail: newEmail,
        currentPassword: currentPassword,
      ),
    );
  }

  // Change the user's password.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _execute(
      () => _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      ),
    );
  }
}
