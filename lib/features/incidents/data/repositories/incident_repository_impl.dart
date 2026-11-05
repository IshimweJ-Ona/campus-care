
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/incident.dart';
import '../../domain/entities/incident_comment.dart';
import '../../domain/repositories/incident_repository.dart';
import '../datasources/incident_remote_datasource.dart';

class IncidentRepositoryImpl implements IncidentRepository {
  IncidentRepositoryImpl({
    required this._remoteDataSource,
  });

  final IncidentRemoteDataSource _remoteDataSource;

  // Convert Firestore data into an Incident entity.
  Incident _mapToIncident(Map<String, dynamic> data) {
    return Incident(
      id: data['id'] as String,
      category: data['category'] as String? ?? '',
      location: data['location'] as String? ?? '',
      description: data['description'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      createdAt: _parseDate(data['createdAt']),
      photoUrl: data['photoUrl'] as String?,
    );
  }

  // Convert Firestore data into an IncidentComment entity.
  IncidentComment _mapToComment(Map<String, dynamic> data) {
    return IncidentComment(
      id: data['id'] as String,
      incidentId: data['incidentId'] as String,
      message: data['message'] as String? ?? '',
      createdAt: _parseDate(data['createdAt']),
      authorName: data['authorName'] as String?,
    );
  }

  // Convert Firestore Timestamp into Dart DateTime.
  DateTime _parseDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.now();
  }

  @override
  Future<String> createIncident({
    required String category,
    required String location,
    required String description,
    String? photoUrl,
  }) {
    return _remoteDataSource.createIncident(
      category: category,
      location: location,
      description: description,
      photoUrl: photoUrl,
    );
  }

  @override
  Future<List<Incident>> getAllIncidents() async {
    final results = await _remoteDataSource.getAllIncidents();

    return results.map(_mapToIncident).toList();
  }

  @override
  Stream<List<Incident>> watchIncidents() {
    return _remoteDataSource.watchIncidents().map(
      (results) => results.map(_mapToIncident).toList(),
    );
  }

  @override
  Future<Incident?> getIncidentById(String incidentId) async {
    final result =
        await _remoteDataSource.getIncidentById(incidentId);

    if (result == null) {
      return null;
    }

    return _mapToIncident(result);
  }

  @override
  Future<void> addComment({
    required String incidentId,
    required String message,
  }) {
    return _remoteDataSource.addComment(
      incidentId: incidentId,
      message: message,
    );
  }

  @override
  Stream<List<IncidentComment>> watchComments(String incidentId) {
    return _remoteDataSource.watchComments(incidentId).map(
      (results) => results.map(_mapToComment).toList(),
    );
  }

  @override
  Future<void> updateIncidentStatus({
    required String incidentId,
    required String status,
  }) {
    return _remoteDataSource.updateIncidentStatus(
      incidentId: incidentId,
      status: status,
    );
  }
}
