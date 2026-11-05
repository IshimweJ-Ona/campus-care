import '../entities/incident.dart';
import '../entities/incident_comment.dart';

abstract class IncidentRepository {
  // submit a new campus incident
  Future<String> createIncident({
    required String category,
    required String location,
    required String description,
    String? photoUrl,
  });

  // Retrieve all incidents for the shared campus incident board.
  Future<List<Incident>> getAllIncidents();

  //Listen for real-time incident updates.
  Stream<List<Incident>> watchIncidents();

  // Retrieve one incident by its ID
  Future<Incident?> getIncidentById(String incidentId);

  //Add a comment to an existing incident.
  Future<void> addComment({
    required String incidentId,
    required String message,
  });

  // Retrieve comments for an incident
  Stream<List<IncidentComment>> watchComments(String incidentId);

  //Update incidents status (approved staff only)
  Future<void> updateIncidentStatus({
    required String incidentId,
    required String status,
  });
}
