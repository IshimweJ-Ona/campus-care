import 'dart:convert';
import 'dart:io';

import 'package:campus_care_app/core/utils/development_test_account.dart';
import 'package:campus_care_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:campus_care_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:campus_care_app/features/incidents/data/datasources/incident_remote_datasource.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:campus_care_app/firebase_options.dart';

const _apiKey = 'fake-api-key';
const _staffEmail = developmentStaffTestEmail;
const _studentPassword = 'CampusCare1!';
const _authEmulatorBase = '/identitytoolkit.googleapis.com/v1';

String get _emulatorHost {
  final configuredHost = Platform.environment['FIREBASE_EMULATOR_HOST'];
  if (configuredHost != null && configuredHost.isNotEmpty) {
    return configuredHost;
  }
  return defaultTargetPlatform == TargetPlatform.android
      ? '10.0.2.2'
      : '127.0.0.1';
}

Uri _authUri(String endpoint) => Uri.parse(
  'http://$_emulatorHost:9099$_authEmulatorBase/$endpoint?key=$_apiKey',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    await FirebaseAuth.instance.useAuthEmulator(_emulatorHost, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(_emulatorHost, 8080);
  });

  testWidgets(
    'emulator auth, incident reporting, staff workflow, and Firestore rules',
    (tester) async {
      expect(
        isDevelopmentStaffTestEnabled,
        isTrue,
        reason: 'Run with --dart-define=USE_FIREBASE_EMULATORS=true in debug.',
      );
      expect(
        Firebase.apps,
        isNotEmpty,
        reason: 'Configure and start Firebase emulators before this test.',
      );

      final staffPassword =
          Platform.environment['CAMPUSCARE_STAFF_TEST_PASSWORD'];
      expect(
        staffPassword,
        isNotNull,
        reason: 'Set CAMPUSCARE_STAFF_TEST_PASSWORD for the local emulator.',
      );
      expect(staffPassword, isNotEmpty);

      final studentEmail =
          'it.${DateTime.now().millisecondsSinceEpoch}@alustudent.com';
      final studentAuth = FirebaseAuth.instance;
      final studentDataSource = AuthRemoteDataSource();
      final studentAuthRepository = AuthRepositoryImpl(studentDataSource);

      await studentDataSource.registerWithEmail(
        name: 'Integration Student',
        email: studentEmail,
        password: _studentPassword,
        selectedRole: 'student',
      );
      var studentFirebaseUser = studentAuth.currentUser!;
      await _markEmailVerified(studentFirebaseUser);
      await studentAuth.signOut();

      final student = await studentAuthRepository.loginWithEmail(
        email: studentEmail,
        password: _studentPassword,
      );
      expect(student.emailVerified, isTrue);
      expect(student.role, 'student');
      expect(student.accountStatus, 'active');
      expect(student.canAccessIncidents, isTrue);
      expect(student.canUseStaffFeatures, isFalse);

      final studentIncidents = IncidentRemoteDataSource();
      final incidentId = await studentIncidents.createIncident(
        category: 'Water Shortage',
        location: 'Integration Test Campus',
        description: 'Water service is unavailable in the library.',
        photoUrl:
            'https://res.cloudinary.com/vbzq5ssu/image/upload/test-fixture.png',
      );
      final allIncidents = await studentIncidents.getAllIncidents();
      expect(
        allIncidents.any((incident) => incident['id'] == incidentId),
        isTrue,
      );
      final savedIncident = await FirebaseFirestore.instance
          .collection('incidents')
          .doc(incidentId)
          .get(const GetOptions(source: Source.server));
      expect(savedIncident.data()?['category'], 'Water Shortage');
      expect(savedIncident.data()?['location'], 'Integration Test Campus');
      expect(savedIncident.data()?['status'], 'pending');

      await studentIncidents.addComment(
        incidentId: incidentId,
        message: 'Please investigate this test report.',
      );
      final comments = await studentIncidents.watchComments(incidentId).first;
      expect(
        comments.single['message'],
        'Please investigate this test report.',
      );

      await _expectPermissionDenied(
        FirebaseFirestore.instance
            .collection('incident_reporters')
            .doc(incidentId)
            .get(const GetOptions(source: Source.server)),
      );
      await _expectPermissionDenied(
        FirebaseFirestore.instance
            .collection('incidents')
            .doc(incidentId)
            .update({
              'status': 'resolved',
              'updatedAt': FieldValue.serverTimestamp(),
            }),
      );

      final pendingStaffEmail =
          'pending.${DateTime.now().millisecondsSinceEpoch}@alustaff.com';
      await studentDataSource.registerWithEmail(
        name: 'Pending Staff',
        email: pendingStaffEmail,
        password: _studentPassword,
        selectedRole: 'staff',
      );
      final pendingFirebaseUser = studentAuth.currentUser!;
      await _markEmailVerified(pendingFirebaseUser);
      await studentAuth.signOut();
      final pendingStaff = await studentAuthRepository.loginWithEmail(
        email: pendingStaffEmail,
        password: _studentPassword,
      );
      expect(pendingStaff.role, 'pending_staff');
      expect(pendingStaff.canUseStaffFeatures, isFalse);
      await _expectPermissionDenied(
        FirebaseFirestore.instance
            .collection('incidents')
            .get(const GetOptions(source: Source.server)),
      );

      await studentAuth.signOut();
      final staff = await studentAuthRepository.loginWithEmail(
        email: _staffEmail,
        password: staffPassword!,
      );
      expect(staff.role, 'staff');
      expect(staff.accountStatus, 'active');
      expect(staff.emailVerified, isTrue);
      expect(staff.canUseStaffFeatures, isTrue);

      final staffIncidents = IncidentRemoteDataSource();
      final staffReports = await staffIncidents.getAllIncidents();
      expect(
        staffReports.any((incident) => incident['id'] == incidentId),
        isTrue,
      );
      final reporter = await staffIncidents.getIncidentReporter(incidentId);
      expect(reporter?['reporterEmail'], studentEmail);
      await staffIncidents.updateIncidentStatus(
        incidentId: incidentId,
        status: 'reviewed',
      );

      await studentAuth.signOut();
      final signedInStudent = await studentAuthRepository.loginWithEmail(
        email: studentEmail,
        password: _studentPassword,
      );
      expect(signedInStudent.canUseStaffFeatures, isFalse);
      final updatedIncident = await FirebaseFirestore.instance
          .collection('incidents')
          .doc(incidentId)
          .get(const GetOptions(source: Source.server));
      expect(updatedIncident.data()?['status'], 'reviewed');

      await studentAuth.signOut();
      await _expectPermissionDenied(
        FirebaseFirestore.instance
            .collection('incidents')
            .get(const GetOptions(source: Source.server)),
      );
      await _expectPermissionDenied(
        FirebaseFirestore.instance.collection('incidents').doc(incidentId).set({
          'category': 'Unauthorized',
        }),
      );
    },
  );
}

Future<void> _markEmailVerified(User user) async {
  final idToken = await user.getIdToken(true);
  final response = await http.post(
    _authUri('accounts:update'),
    headers: const {'content-type': 'application/json'},
    body: jsonEncode({
      'idToken': idToken,
      'emailVerified': true,
      'returnSecureToken': true,
    }),
  );
  if (response.statusCode != 200) {
    throw StateError(
      'The Auth emulator could not verify the test account: ${response.body}',
    );
  }
  await user.reload();
}

Future<void> _expectPermissionDenied(Future<Object?> operation) async {
  try {
    await operation;
  } on FirebaseException catch (error) {
    expect(error.code, 'permission-denied');
    return;
  }
  fail('Expected Firestore to reject an unauthorized operation.');
}
