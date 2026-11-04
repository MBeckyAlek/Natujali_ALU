enum UserRole { student, staff }

class AppUser {
  const AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.studentId,
    required this.role,
    required this.emailVerified,
  });

  final String uid;
  final String fullName;
  final String email;
  final String studentId;
  final UserRole role;
  final bool emailVerified;

  String get firstName => fullName.split(' ').first;

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  AppUser copyWith({bool? emailVerified}) {
    return AppUser(
      uid: uid,
      fullName: fullName,
      email: email,
      studentId: studentId,
      role: role,
      emailVerified: emailVerified ?? this.emailVerified,
    );
  }
}
