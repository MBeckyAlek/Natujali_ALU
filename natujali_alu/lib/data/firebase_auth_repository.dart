import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/utils/validators.dart';
import '../models/app_user.dart';
import 'auth_repository.dart';

/// Firebase Authentication with each person's profile (name and student ID)
/// stored in the Firestore `users` collection.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  @override
  Stream<AppUser?> authStateChanges() {
    // idTokenChanges also fires after reloadUser refreshes the token, which
    // is how the app notices that the email has just been verified.
    return _auth.idTokenChanges().asyncMap(
      (user) => user == null ? null : _loadProfile(user),
    );
  }

  @override
  Future<void> signIn({required String email, required String password}) {
    return _guard(
      () => _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      ),
    );
  }

  @override
  Future<void> register({
    required String fullName,
    required String email,
    required String studentId,
    required String password,
  }) {
    return _guard(() async {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user!;
      await user.updateDisplayName(fullName.trim());
      await _users.doc(user.uid).set({
        'fullName': fullName.trim(),
        'email': user.email,
        'studentId': studentId.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      await user.sendEmailVerification();
    });
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      // Stay quiet about unknown emails so nobody can probe for accounts.
      if (e.code == 'user-not-found') return;
      throw AuthException(_messageFor(e));
    }
  }

  @override
  Future<void> resendVerificationEmail() {
    return _guard(() async => _auth.currentUser?.sendEmailVerification());
  }

  @override
  Future<void> reloadUser() {
    return _guard(() async {
      final user = _auth.currentUser;
      if (user == null) return;
      await user.reload();
      // A fresh token carries email_verified = true, which the Firestore
      // security rules check, and makes idTokenChanges emit.
      await _auth.currentUser?.getIdToken(true);
    });
  }

  @override
  Future<void> signOut() => _auth.signOut();

  Future<AppUser> _loadProfile(User user) async {
    final email = user.email ?? '';
    Map<String, dynamic>? profile;
    try {
      profile = (await _users.doc(user.uid).get()).data();
    } on FirebaseException {
      // Fall back to what Firebase Auth knows if the profile can't be read.
    }
    return AppUser(
      uid: user.uid,
      fullName: profile?['fullName'] as String? ?? user.displayName ?? email,
      email: email,
      studentId: profile?['studentId'] as String? ?? '',
      role: email.endsWith('@${Validators.staffDomain}')
          ? UserRole.staff
          : UserRole.student,
      emailVerified: user.emailVerified,
    );
  }

  /// Runs a Firebase call and turns its errors into friendly messages.
  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    } on FirebaseException {
      throw const AuthException(
        'Something went wrong on our side. Please try again.',
      );
    }
  }

  String _messageFor(FirebaseAuthException e) {
    return switch (e.code) {
      // One message for all of these so we don't reveal whether an account exists.
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' ||
      'invalid-email' =>
        "Email or password isn't correct. Try again or reset your password.",
      'email-already-in-use' =>
        'An account with this email already exists. Try signing in.',
      'weak-password' => 'Choose a stronger password.',
      'user-disabled' => 'This account has been disabled. Contact support.',
      'too-many-requests' =>
        'Too many attempts. Wait a few minutes and try again.',
      'network-request-failed' =>
        'No internet connection. Check your network and try again.',
      _ => 'Something went wrong. Please try again.',
    };
  }
}
