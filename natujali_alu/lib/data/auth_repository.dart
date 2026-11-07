import '../models/app_user.dart';

/// Everything the app needs from an authentication backend.
///
/// The UI only talks to this interface, so the in-memory version used during
/// development can be swapped for Firebase Authentication without touching
/// any screens.
abstract class AuthRepository {
  /// Emits the signed-in user, or null when signed out.
  Stream<AppUser?> authStateChanges();

  /// Signs in and returns the user, so the caller can check their role.
  Future<AppUser> signIn({required String email, required String password});

  /// Creates a student account and sends a verification email.
  Future<void> register({
    required String fullName,
    required String email,
    required String studentId,
    required String password,
  });

  Future<void> sendPasswordReset(String email);

  Future<void> resendVerificationEmail();

  /// Re-fetches the current user, e.g. to see if they verified their email.
  Future<void> reloadUser();

  Future<void> signOut();

  /// Staff only: looks up a reporter's profile, or null if not found.
  Future<AppUser?> fetchUser(String uid);
}

/// A failure with a message that is safe to show to the user.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
