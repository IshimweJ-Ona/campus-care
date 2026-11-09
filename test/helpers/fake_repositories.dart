import 'dart:async';

import 'package:campus_care_app/features/auth/domain/entities/app_user.dart';
import 'package:campus_care_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:campus_care_app/features/incidents/data/datasources/incident_remote_datasource.dart';
import 'package:campus_care_app/features/incidents/domain/entities/incident.dart';
import 'package:campus_care_app/features/incidents/domain/entities/incident_comment.dart';
import 'package:campus_care_app/features/incidents/domain/entities/incident_reporter.dart';
import 'package:campus_care_app/features/incidents/domain/repositories/incident_repository.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.user});

  AppUser? user;
  Object? loginError;
  Completer<AppUser>? loginCompleter;
  String? registeredEmail;

  @override
  Future<void> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required String selectedRole,
  }) async {
    registeredEmail = email;
  }

  @override
  Future<AppUser?> signInWithGoogle({required String selectedRole}) async =>
      user;

  @override
  Future<AppUser> loginWithEmail({
    required String email,
    required String password,
  }) async {
    if (loginCompleter != null) return loginCompleter!.future;
    if (loginError != null) throw loginError!;
    if (user == null) throw StateError('No fake user configured.');
    return user!;
  }

  @override
  Future<AppUser> loginWithGoogle() async {
    if (user == null) throw StateError('No fake user configured.');
    return user!;
  }

  @override
  Future<AppUser?> getCurrentUser() async => user;

  @override
  Future<void> resendVerificationEmail() async {}

  @override
  Future<AppUser> completeEmailVerification() async => user!;

  @override
  Future<void> signOut() async {
    user = null;
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}

  @override
  Future<void> updateName({required String name}) async {}

  @override
  Future<void> updatePhotoUrl({required String? photoUrl}) async {}

  @override
  Future<void> changeEmail({
    required String newEmail,
    required String currentPassword,
  }) async {}

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}
}

class FakeIncidentRepository implements IncidentRepository {
  List<Incident> incidents = [];
  Incident? incident;
  IncidentReporter? reporter;
  List<IncidentComment> comments = [];
  Object? createError;
  Completer<String>? createCompleter;
  String? createdCategory;
  String? createdLocation;
  String? createdDescription;
  String? postedComment;
  String? updatedStatus;
  int createCalls = 0;

  @override
  Future<String> createIncident({
    required String category,
    required String location,
    required String description,
    String? photoUrl,
  }) async {
    createCalls++;
    createdCategory = category;
    createdLocation = location;
    createdDescription = description;
    if (createCompleter != null) return createCompleter!.future;
    if (createError != null) throw createError!;
    return 'created-incident';
  }

  @override
  Future<List<Incident>> getAllIncidents() async => incidents;

  @override
  Stream<List<Incident>> watchIncidents() => Stream.value(incidents);

  @override
  Future<Incident?> getIncidentById(String incidentId) async => incident;

  @override
  Future<IncidentReporter?> getIncidentReporter(String incidentId) async =>
      reporter;

  @override
  Future<void> addComment({
    required String incidentId,
    required String message,
  }) async {
    postedComment = message;
  }

  @override
  Stream<List<IncidentComment>> watchComments(String incidentId) =>
      Stream.value(comments);

  @override
  Future<void> updateIncidentStatus({
    required String incidentId,
    required String status,
  }) async {
    updatedStatus = status;
  }
}

class FakeIncidentRemoteDataSource implements IncidentRemoteDataSource {
  List<Map<String, dynamic>> incidents = [];
  List<Map<String, dynamic>> comments = [];

  @override
  Future<List<Map<String, dynamic>>> getAllIncidents() async => incidents;

  @override
  Stream<List<Map<String, dynamic>>> watchIncidents() =>
      Stream.value(incidents);

  @override
  Future<Map<String, dynamic>?> getIncidentById(String incidentId) async {
    for (final incident in incidents) {
      if (incident['id'] == incidentId) return incident;
    }
    return null;
  }

  @override
  Future<Map<String, dynamic>?> getIncidentReporter(
    String incidentId,
  ) async =>
      null;

  @override
  Stream<List<Map<String, dynamic>>> watchComments(String incidentId) =>
      Stream.value(comments);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
