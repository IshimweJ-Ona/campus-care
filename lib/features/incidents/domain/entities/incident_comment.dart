
class IncidentComment {
  const IncidentComment({
    required this.id,
    required this.incidentId,
    required this.message,
    required this.createdAt,
    this.authorName,
  });

  final String id;
  final String incidentId;
  final String message;
  final DateTime createdAt;

  // Only populated when the viewer is approved staff.
  final String? authorName;
}
