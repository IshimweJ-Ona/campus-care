
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/incident_remote_datasource.dart';
import '../../data/repositories/incident_repository_impl.dart';
import '../../domain/entities/incident.dart';
import '../../domain/entities/incident_comment.dart';
import '../../domain/repositories/incident_repository.dart';

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

// Real-time comments for a specific incident
final incidentCommentsProvider =
    StreamProvider.family<List<IncidentComment>, String>(
  (ref, incidentId) {
    final repository = ref.watch(incidentRepositoryProvider);
    return repository.watchComments(incidentId);
  },
);
