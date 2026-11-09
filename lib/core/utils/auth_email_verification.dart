class AuthEmailVerification {
  AuthEmailVerification._();

  static bool isVerified({
    required bool authUserVerified,
    required bool tokenVerified,
    required String? authenticatedEmail,
    required String? tokenEmail,
  }) {
    return authUserVerified &&
        tokenVerified &&
        authenticatedEmail != null &&
        authenticatedEmail == tokenEmail;
  }
}
