import 'dart:async';

import '../models/app_user.dart';
import 'auth_repository.dart';

/// In-memory stand-in for Firebase Authentication, used until the Firebase
/// project is connected. Data resets when the app restarts.
///
/// Demo login: a.hassan@alustudent.com / password1
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository() {
    _accounts[demoStudent.email] = _FakeAccount('password1', demoStudent);
  }

  static const demoStudent = AppUser(
    uid: 'student-1',
    fullName: 'Amina Hassan',
    email: 'a.hassan@alustudent.com',
    studentId: 'ALU-2024-0816',
    role: UserRole.student,
    emailVerified: true,
  );

  final _accounts = <String, _FakeAccount>{};
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _currentUser;

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield _currentUser;
    yield* _controller.stream;
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _simulateNetwork();
    final account = _accounts[email.trim().toLowerCase()];
    if (account == null || account.password != password) {
      // Same message either way so we don't reveal whether an account exists.
      throw const AuthException(
        "Email or password isn't correct. Try again or reset your password.",
      );
    }
    _setUser(account.user);
  }

  @override
  Future<void> register({
    required String fullName,
    required String email,
    required String studentId,
    required String password,
  }) async {
    await _simulateNetwork();
    final key = email.trim().toLowerCase();
    if (_accounts.containsKey(key)) {
      throw const AuthException(
        'An account with this email already exists. Try signing in.',
      );
    }
    final user = AppUser(
      uid: 'student-${_accounts.length + 1}',
      fullName: fullName.trim(),
      email: key,
      studentId: studentId.trim(),
      role: UserRole.student,
      emailVerified: false,
    );
    _accounts[key] = _FakeAccount(password, user);
    _setUser(user);
  }

  @override
  Future<void> sendPasswordReset(String email) => _simulateNetwork();

  @override
  Future<void> resendVerificationEmail() => _simulateNetwork();

  @override
  Future<void> reloadUser() async {
    await _simulateNetwork();
    final user = _currentUser;
    if (user == null) return;
    // There is no real inbox here, so treat the link as clicked.
    final verified = user.copyWith(emailVerified: true);
    _accounts[user.email] = _FakeAccount(
      _accounts[user.email]!.password,
      verified,
    );
    _setUser(verified);
  }

  @override
  Future<void> signOut() async => _setUser(null);

  void _setUser(AppUser? user) {
    _currentUser = user;
    _controller.add(user);
  }

  Future<void> _simulateNetwork() =>
      Future.delayed(const Duration(milliseconds: 600));
}

class _FakeAccount {
  const _FakeAccount(this.password, this.user);

  final String password;
  final AppUser user;
}
