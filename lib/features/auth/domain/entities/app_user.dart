
class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.emailVerified = false,
    this.role = 'student',
    this.accountStatus = 'active',
  });

  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final bool emailVerified;
  final String role;
  final String accountStatus;

  AppUser copyWith({
    String? email,
    String? displayName,
    String? photoUrl,
    bool? emailVerified,
    String? role,
    String? accountStatus,
    bool clearPhotoUrl = false,
  }) {
    return AppUser(
      id: id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: clearPhotoUrl ? null : photoUrl ?? this.photoUrl,
      emailVerified: emailVerified ?? this.emailVerified,
      role: role ?? this.role,
      accountStatus: accountStatus ?? this.accountStatus,
    );
  }
}
