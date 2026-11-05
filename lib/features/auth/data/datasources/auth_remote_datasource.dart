
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

  Future<void> _createUserProfile({
    required User user,
    required String selectedRole,
    String? name,
  }) async {
    if (selectedRole != 'student' && selectedRole != 'staff') {
      throw ArgumentError('Invalid account role.');
    }

    final isStudent = selectedRole == 'student';

    await _firestore.collection('users').doc(user.uid).set({
      'name': name ?? user.displayName ?? '',
      'email': user.email ?? '',
      'photoUrl': user.photoURL,
      'role': isStudent ? 'student' : 'pending_staff',
      'accountStatus': isStudent ? 'active' : 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Register using email and password.
  Future<UserCredential> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required String selectedRole,
  }) async {
    _checkFirebase();

    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;

    if (user == null) {
      throw StateError('Firebase did not create the user.');
    }

    try {
      await user.updateDisplayName(name.trim());

      await _createUserProfile(
        user: user,
        selectedRole: selectedRole,
        name: name.trim(),
      );

      return credential;
    } catch (_) {
      await user.delete();
      rethrow;
    }
  }

  // Register or sign in using Google.
  Future<UserCredential?> signInWithGoogle({
    required String selectedRole,
  }) async {
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

    final user = credential.user;

    if (user == null) {
      return null;
    }

    final userDocument = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();

    if (!userDocument.exists) {
      await _createUserProfile(
        user: user,
        selectedRole: selectedRole,
      );
    }

    return credential;
  }

  // Login using email and password.
  Future<UserCredential> loginWithEmail({
    required String email,
    required String password,
  }) async {
    _checkFirebase();

    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
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

  // Retrieve the authenticated user's Firestore profile.
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    _checkFirebase();

    final user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    final document = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();

    if (!document.exists) {
      return null;
    }

    return document.data();
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
