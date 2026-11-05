
class Incident {
  const Incident({
    required this.id,
    required this.category,
    required this.location,
    required this.description,
    required this.status,
    required this.createdAt,
    this.photoUrl,
  });

  final String id;
  final String category;
  final String location;
  final String description;
  final String status;
  final DateTime createdAt;
  final String? photoUrl;

  Incident copyWith({
    String? id,
    String? category,
    String? location,
    String? description,
    String? status,
    DateTime? createdAt,
    String? photoUrl,
  }) {
    return Incident(
      id: id ?? this.id,
      category: category ?? this.category,
      location: location ?? this.location,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
