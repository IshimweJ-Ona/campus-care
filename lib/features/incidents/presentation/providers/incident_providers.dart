
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/incident_remote_datasource.dart';
import '../../data/repositories/incident_repository_impl.dart';
import '../../domain/entities/incident.dart';
import '../../domain/entities/incident_comment.dart';
import '../../domain/entities/incident_reporter.dart';
import '../../domain/repositories/incident_repository.dart';

final reportedIncidentLookupProvider =
    Provider<Future<bool> Function(String incidentId)>((ref) {
  return (incidentId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return false;

    final document = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('reported_incidents')
        .doc(incidentId)
        .get();
    return document.exists;
  };
});

final isMyIncidentProvider = FutureProvider.family<bool, String>(
  (ref, incidentId) {
    return ref.watch(reportedIncidentLookupProvider)(incidentId);
  },
);

// Firestore data source provider
final incidentRemoteDataSourceProvider =
    Provider<IncidentRemoteDataSource>((ref) {
  return IncidentRemoteDataSource();
});

// Incident repository provider
final incidentRepositoryProvider = Provider<IncidentRepository>((ref) {
  return IncidentRepositoryImpl(
    remoteDataSource: ref.watch(incidentRemoteDataSourceProvider),
  );
});

// Real-time stream of all incidents
final incidentsStreamProvider =
    StreamProvider<List<Incident>>((ref) {
  final repository = ref.watch(incidentRepositoryProvider);
  return repository.watchIncidents();
});

// Fetch a single incident by ID
final incidentDetailsProvider =
    FutureProvider.family<Incident?, String>((ref, incidentId) {
  final repository = ref.watch(incidentRepositoryProvider);
  return repository.getIncidentById(incidentId);
});

// Private reporter details; the data source verifies approved staff access.
final incidentReporterProvider =
    FutureProvider.family<IncidentReporter?, String>(
  (ref, incidentId) {
    final repository = ref.watch(incidentRepositoryProvider);
    return repository.getIncidentReporter(incidentId);
  },
);

// Real-time comments for a specific incident
final incidentCommentsProvider =
    StreamProvider.family<List<IncidentComment>, String>(
  (ref, incidentId) {
    final repository = ref.watch(incidentRepositoryProvider);
    return repository.watchComments(incidentId);
  },
);
