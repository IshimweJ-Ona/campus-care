
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/utils/incident_validation.dart';
import '../../../../core/utils/validators.dart';

class IncidentRemoteDataSource {
  IncidentRemoteDataSource({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // Firestore collections.
  CollectionReference<Map<String, dynamic>> get _incidents =>
      _firestore.collection('incidents');

  CollectionReference<Map<String, dynamic>> get _reporters =>
      _firestore.collection('incident_reporters');

  CollectionReference<Map<String, dynamic>> get _commentAuthors =>
      _firestore.collection('incident_comment_authors');

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  // Get the currently authenticated user.
  User get _currentUser {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('You must be logged in to perform this action.');
    }

    return user;
  }

  // Get the current user's Firestore profile.
  Future<Map<String, dynamic>> _getUserProfile() async {
    final user = _currentUser;
    final userReference = _users.doc(user.uid);
    var document = await userReference.get();

    if (!document.exists) {
      throw Exception('Your user profile could not be found.');
    }

    var data = document.data();
    if (data == null) {
      throw StateError('Your user profile could not be read.');
    }

    if (!data.containsKey('photoUrl')) {
      await userReference.update({'photoUrl': user.photoURL});
      document = await userReference.get();
      data = document.data();
      if (data == null) {
        throw StateError('Your user profile could not be read.');
      }
    }

    final name = data['name'];
    final email = data['email'];
    final photoUrl = data['photoUrl'];
    if (name is! String ||
        email is! String ||
        email != user.email ||
        (photoUrl != null && photoUrl is! String)) {
      throw StateError(
        'Your CampusCare profile is incomplete or does not match your '
        'authenticated account. Please contact support.',
      );
    }

    return {
      'uid': user.uid,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'role': data['role'],
      'accountStatus': data['accountStatus'],
    };
  }

  Future<void> _ensureVerifiedAluEmail(User user) async {
    await user.reload();
    final refreshedUser = _auth.currentUser;
    if (refreshedUser == null) {
      throw StateError('Your session expired. Please sign in again.');
    }

    final email = refreshedUser.email;
    if (Validators.validateAluEmail(email) != null) {
      throw StateError(
        'Only verified @alustudent.com and @alustaff.com accounts can '
        'submit incidents.',
      );
    }

    final token = await refreshedUser.getIdTokenResult(true);
    final claims = token.claims ?? const <String, dynamic>{};
    if (refreshedUser.emailVerified != true ||
        claims['email_verified'] != true ||
        claims['email'] != email) {
      throw StateError(
        'Verify your ALU email address before submitting an incident.',
      );
    }
  }

  // Check whether the current user is approved staff.
  Future<bool> _isApprovedStaff() async {
    final profile = await _getUserProfile();

    return profile['role'] == 'staff' &&
        profile['accountStatus'] == 'active';
  }

  // Convert an incident document into a map.
  Map<String, dynamic> _incidentFromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data()!;

    return {
      'id': document.id,
      'category': data['category'],
      'location': data['location'],
      'description': data['description'],
      'status': data['status'],
      'photoUrl': data['photoUrl'],
      'createdAt': data['createdAt'],
    };
  }

  // Create a new incident.
  Future<String> createIncident({
    required String category,
    required String location,
    required String description,
    String? photoUrl,
  }) async {
    final categoryError = IncidentValidation.validateCategory(category);
    final locationError = IncidentValidation.validateLocation(location);
    final descriptionError = IncidentValidation.validateDescription(description);
    if (categoryError != null ||
        locationError != null ||
        descriptionError != null) {
      throw ArgumentError(
        categoryError ?? locationError ?? descriptionError,
      );
    }

    final user = _currentUser;
    await _ensureVerifiedAluEmail(user);

    final profile = await _getUserProfile();

    if (profile['role'] != 'student' ||
        profile['accountStatus'] != 'active') {
      throw Exception('Only active students can report incidents.');
    }

    // Generate a unique incident document reference.
    final incidentReference = _incidents.doc();

    // Generate the private reporter document reference.
    final reporterReference = _reporters.doc(incidentReference.id);

    // Generate the student's private incident reference.
    final userIncidentRef = _users
        .doc(user.uid)
        .collection('reported_incidents')
        .doc(incidentReference.id);

    // Create one batch for all three documents.
    final batch = _firestore.batch();

    // 1. Public incident information.
    batch.set(incidentReference, {
      'category': category,
      'location': location,
      'description': description,
      'status': 'pending',
      'photoUrl': photoUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 2. Private reporter information.
    // Only approved staff can read this document.
    batch.set(reporterReference, {
      'incidentId': incidentReference.id,
      'reporterId': profile['uid'],
      'reporterName': profile['name'],
      'reporterEmail': profile['email'],
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 3. Private reference for the reporting student.
    // This allows students to identify their own reports
    // without accessing private reporter information.
    batch.set(userIncidentRef, {
      'incidentId': incidentReference.id,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Commit all three documents atomically.
    await batch.commit();

    return incidentReference.id;
  }


  // Get all incidents.
  Future<List<Map<String, dynamic>>> getAllIncidents() async {
    final snapshot = await _incidents
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((document) => _incidentFromDocument(document))
        .toList();
  }

  // Listen for real-time incident updates.
  Stream<List<Map<String, dynamic>>> watchIncidents() {
    return _incidents
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((document) => _incidentFromDocument(document))
              .toList(),
        );
  }

  // Get one incident by its document ID.
  Future<Map<String, dynamic>?> getIncidentById(
    String incidentId,
  ) async {
    final document = await _incidents.doc(incidentId).get();

    if (!document.exists) {
      return null;
    }

    return _incidentFromDocument(document);
  }

  // Private reporter data is available only to approved staff.
  Future<Map<String, dynamic>?> getIncidentReporter(
    String incidentId,
  ) async {
    if (!await _isApprovedStaff()) {
      throw Exception('Only approved staff can view reporter details.');
    }

    final document = await _reporters.doc(incidentId).get();
    if (!document.exists) {
      return null;
    }

    final data = document.data()!;
    return {
      'reporterName': data['reporterName'],
      'reporterEmail': data['reporterEmail'],
      'reporterPhotoUrl': data['reporterPhotoUrl'],
    };
  }

  // Add a comment to an existing incident.
  Future<void> addComment({
    required String incidentId,
    required String message,
  }) async {
    final profile = await _getUserProfile();

    final isStudent = profile['role'] == 'student' &&
        profile['accountStatus'] == 'active';

    final isStaff = profile['role'] == 'staff' &&
        profile['accountStatus'] == 'active';

    if (!isStudent && !isStaff) {
      throw Exception('Your account is not authorized to comment.');
    }

    final incidentReference = _incidents.doc(incidentId);

    final incidentDocument = await incidentReference.get();

    if (!incidentDocument.exists) {
      throw Exception('This incident does not exist.');
    }

    final commentReference =
        incidentReference.collection('comments').doc();

    final authorReference = _commentAuthors.doc(commentReference.id);

    final batch = _firestore.batch();

    // Public comment: no author identity.
    batch.set(commentReference, {
      'incidentId': incidentId,
      'message': message.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Private commenter information.
    batch.set(authorReference, {
      'commentId': commentReference.id,
      'incidentId': incidentId,
      'authorId': profile['uid'],
      'authorName': profile['name'],
      'authorEmail': profile['email'],
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // Listen to comments for an incident.
  // Only approved staff receive commenter names.
  Stream<List<Map<String, dynamic>>> watchComments(
    String incidentId,
  ) async* {
    final isStaff = await _isApprovedStaff();

    final commentsReference =
        _incidents.doc(incidentId).collection('comments');

    await for (final snapshot in commentsReference
        .orderBy('createdAt', descending: false)
        .snapshots()) {
      final comments = <Map<String, dynamic>>[];

      for (final document in snapshot.docs) {
        final data = document.data();

        String? authorName;

        if (isStaff) {
          final authorDocument =
              await _commentAuthors.doc(document.id).get();

          if (authorDocument.exists) {
            authorName =
                authorDocument.data()?['authorName'] as String?;
          }
        }

        comments.add({
          'id': document.id,
          'incidentId': data['incidentId'],
          'message': data['message'],
          'createdAt': data['createdAt'],
          'authorName': authorName,
        });
      }

      yield comments;
    }
  }

  // Update an incident's status.
  // Firestore security rules must also enforce staff authorization.
  Future<void> updateIncidentStatus({
    required String incidentId,
    required String status,
  }) async {
    if (IncidentValidation.validateStatus(status) != null) {
      throw ArgumentError('Invalid incident status.');
    }

    if (!await _isApprovedStaff()) {
      throw Exception('Only approved staff can update incident status.');
    }

    await _incidents.doc(incidentId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
