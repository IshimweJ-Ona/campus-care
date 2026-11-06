class IncidentReporter {
  const IncidentReporter({
    required this.name,
    required this.email,
    this.photoUrl,
  });

  final String name;
  final String email;
  final String? photoUrl;
}
