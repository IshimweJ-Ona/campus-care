
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/utils/validators.dart';

class AuthenticatedUserSession {
  const AuthenticatedUserSession({
    required this.user,
    required this.email,
    required this.emailVerified,
    required this.profile,
  });

  final User user;
  final String email;
  final bool emailVerified;
  final Map<String, dynamic>? profile;
}

class AuthRemoteDataSource {
  AuthRemoteDataSource({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  Future<void>? _googleSignInInitialization;

  User? get currentUser => _auth.currentUser;

  Future<void> _initializeGoogleSignIn() {
    return _googleSignInInitialization ??=
        _googleSignIn.initialize();
  }

  void _checkFirebase() {
    if (Firebase.apps.isEmpty) {
      throw StateError('Firebase is not initialized.');
    }
  }

  void _validateEmailAndRole({
    required String email,
    required String selectedRole,
  }) {
    final validationError = Validators.validateAluEmail(email);
    if (validationError != null) {
      throw ArgumentError(validationError);
    }

    if (Validators.roleForAluEmail(email) != selectedRole) {
      throw ArgumentError(
        'Use an ${selectedRole == 'student' ? '@alustudent.com' : '@alustaff.com'} '
        'email address for the selected account role.',
      );
    }
  }

  Future<Map<String, dynamic>> _getOrCreateUserProfile({
    required User user,
    required String authenticatedEmail,
    String? requiredNewAccountRole,
  }) async {
    final roleForEmail = Validators.roleForAluEmail(authenticatedEmail);
    if (roleForEmail == null) {
      throw StateError('This account does not use a supported ALU email.');
    }

    final userDocument = _firestore.collection('users').doc(user.uid);
    final profile = await _firestore
        .runTransaction<Map<String, dynamic>>((transaction) async {
      final snapshot = await transaction.get(userDocument);
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data == null) {
          throw StateError('Your CampusCare profile could not be read.');
        }
        return data;
      }

      if (requiredNewAccountRole != null &&
          requiredNewAccountRole != roleForEmail) {
        throw ArgumentError(
          'Use an ${requiredNewAccountRole == 'student' ? '@alustudent.com' : '@alustaff.com'} '
          'email address for the selected account role.',
        );
      }

      final isStudent = roleForEmail == 'student';
      final data = <String, dynamic>{
        'name': user.displayName ?? '',
        'email': authenticatedEmail,
        'photoUrl': user.photoURL,
        'role': isStudent ? 'student' : 'pending_staff',
        'accountStatus': isStudent ? 'active' : 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      transaction.set(userDocument, data);
      return data;
    });

    _validateUserProfile(
      profile: profile,
      email: authenticatedEmail,
      roleForEmail: roleForEmail,
    );

    return profile;
  }

  void _validateUserProfile({
    required Map<String, dynamic> profile,
    required String email,
    required String roleForEmail,
  }) {
    final role = profile['role'];
    final accountStatus = profile['accountStatus'];
    final isStudentProfile =
        roleForEmail == 'student' &&
        role == 'student' &&
        accountStatus == 'active';
    final isActiveStaffProfile =
        roleForEmail == 'staff' &&
        role == 'staff' &&
        accountStatus == 'active';
    final isPendingStaffProfile =
        roleForEmail == 'staff' &&
        role == 'pending_staff' &&
        accountStatus == 'pending';

    if (profile['email'] != email ||
        (!isStudentProfile &&
            !isActiveStaffProfile &&
            !isPendingStaffProfile)) {
      throw StateError(
        'Your CampusCare profile does not match your verified ALU account. '
        'Please contact support.',
      );
    }
  }

  Future<AuthenticatedUserSession?> loadAuthenticatedUser({
    String? requiredNewAccountRole,
  }) async {
    _checkFirebase();

    final initialUser = _auth.currentUser;
    if (initialUser == null) return null;

    await initialUser.reload();
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Your Firebase session has expired. Please sign in again.');
    }

    final email = user.email;
    final emailError = Validators.validateAluEmail(email);
    if (emailError != null) {
      throw StateError(emailError);
    }

    final tokenResult = await user.getIdTokenResult(true);
    final claims = tokenResult.claims ?? const <String, dynamic>{};
    final tokenEmail = claims['email'];
    if (tokenEmail is! String || tokenEmail != email) {
      throw StateError(
        'Firebase could not confirm the email on your account. '
        'Please sign in again.',
      );
    }

    final emailVerified =
        user.emailVerified && claims['email_verified'] == true;
    if (!emailVerified) {
      if (requiredNewAccountRole != null &&
          Validators.roleForAluEmail(email) != requiredNewAccountRole) {
        _validateEmailAndRole(
          email: email!,
          selectedRole: requiredNewAccountRole,
        );
      }

      return AuthenticatedUserSession(
        user: user,
        email: tokenEmail,
        emailVerified: false,
        profile: null,
      );
    }

    final profile = await _getOrCreateUserProfile(
      user: user,
      authenticatedEmail: tokenEmail,
      requiredNewAccountRole: requiredNewAccountRole,
    );

    return AuthenticatedUserSession(
      user: user,
      email: tokenEmail,
      emailVerified: true,
      profile: profile,
    );
  }

  Future<void> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required String selectedRole,
  }) async {
    _checkFirebase();

    final normalizedEmail = Validators.normalizeEmail(email);
    _validateEmailAndRole(
      email: normalizedEmail,
      selectedRole: selectedRole,
    );

    final credential = await _auth.createUserWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );

    final user = credential.user;

    if (user == null) {
      throw StateError('Firebase did not create the user.');
    }

    await user.updateDisplayName(name.trim());
    await user.sendEmailVerification();
  }

  // Register or sign in using Google.
  Future<UserCredential?> signInWithGoogle() async {
    _checkFirebase();

    await _initializeGoogleSignIn();

    final googleUser = await _googleSignIn.authenticate();
    final googleAuth = googleUser.authentication;

    final oauthCredential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final credential = await _auth.signInWithCredential(
      oauthCredential,
    );

    return credential;
  }

  // Login using email and password.
  Future<UserCredential> loginWithEmail({
    required String email,
    required String password,
  }) async {
    _checkFirebase();

    final normalizedEmail = Validators.normalizeEmail(email);
    final emailError = Validators.validateAluEmail(normalizedEmail);
    if (emailError != null) {
      throw ArgumentError(emailError);
    }

    return _auth.signInWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );
  }

  // Login using an existing Google account.
  Future<UserCredential> loginWithGoogle() async {
    _checkFirebase();

    await _initializeGoogleSignIn();

    final googleUser = await _googleSignIn.authenticate();
    final googleAuth = googleUser.authentication;

    final oauthCredential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    return _auth.signInWithCredential(oauthCredential);
  }

  Future<void> resendVerificationEmail() async {
    _checkFirebase();

    final session = await loadAuthenticatedUser();
    if (session == null) {
      throw StateError('Sign in before requesting a verification email.');
    }
    if (session.emailVerified) {
      throw StateError('Your email address is already verified.');
    }

    await session.user.sendEmailVerification();
  }

  // Update the user's full name.
  Future<void> updateName({
    required String name,
  }) async {
    _checkFirebase();

    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('You must be logged in to update your profile.');
    }

    final updatedName = name.trim();

    if (updatedName.isEmpty) {
      throw ArgumentError('Name cannot be empty.');
    }

    await user.updateDisplayName(updatedName);

    await _firestore.collection('users').doc(user.uid).update({
      'name': updatedName,
    });
  }

  // Update or remove the user's Cloudinary profile picture URL.
  Future<void> updatePhotoUrl({
    required String? photoUrl,
  }) async {
    _checkFirebase();

    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('You must be logged in to update your profile.');
    }

    await _firestore.collection('users').doc(user.uid).update({
      'photoUrl': photoUrl,
    });

    await user.updatePhotoURL(photoUrl);
  }

  // Reauthenticate an email/password account.
  Future<void> _reauthenticateWithPassword({
    required User user,
    required String password,
  }) async {
    final email = user.email;

    if (email == null || email.isEmpty) {
      throw StateError('Your account does not have an email address.');
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    await user.reauthenticateWithCredential(credential);
  }

  
  // Change the user's email address.
  Future<void> changeEmail({
    required String newEmail,
    required String currentPassword,
  }) async {
    _checkFirebase();

    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('You must be logged in to change your email.');
    }

    final email = newEmail.trim().toLowerCase();

    if (email.isEmpty || !email.contains('@')) {
      throw ArgumentError('Please enter a valid email address.');
    }

    await _reauthenticateWithPassword(
      user: user,
      password: currentPassword,
    );

    await user.verifyBeforeUpdateEmail(email);
  }


  // Change the user's password.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _checkFirebase();

    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('You must be logged in to change your password.');
    }

    final hasPasswordProvider = user.providerData.any(
      (provider) => provider.providerId == 'password',
    );

    if (!hasPasswordProvider) {
      throw StateError(
        'Password changes are only available for email/password accounts.',
      );
    }

    if (newPassword.length < 6) {
      throw ArgumentError(
        'Your new password must contain at least 6 characters.',
      );
    }

    await _reauthenticateWithPassword(
      user: user,
      password: currentPassword,
    );

    await user.updatePassword(newPassword);
  }

  // Sign out from Firebase and Google.
  Future<void> signOut() async {
    _checkFirebase();

    await _auth.signOut();

    await _initializeGoogleSignIn();
    await _googleSignIn.signOut();
  }

  // Send a password reset email.
  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    _checkFirebase();

    await _auth.sendPasswordResetEmail(
      email: email.trim(),
    );
  }
}
