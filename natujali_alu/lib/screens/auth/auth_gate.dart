import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_user.dart';
import '../../providers/auth_providers.dart';
import '../../providers/session_providers.dart';
import '../shell/main_shell.dart';
import '../staff/staff_shell.dart';
import 'sign_in_screen.dart';
import 'verify_email_screen.dart';

/// Decides which part of the app to show based on the auth state:
/// signed out → sign in, unverified → verify email, then the staff or
/// student app depending on the portal chosen at sign-in.
///
/// Because it watches [authStateProvider], signing in or out anywhere in the
/// app automatically swaps the screen here. It also ends the session when
/// the app returns from the background after too long.
class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    final session = ref.read(sessionProvider.notifier);
    _lifecycle = AppLifecycleListener(
      onHide: session.recordActivity,
      onShow: session.checkOnResume,
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final portal = ref.watch(sessionProvider);

    return authState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => const SignInScreen(),
      data: (user) {
        if (user == null) return const SignInScreen();
        if (!user.emailVerified) return VerifyEmailScreen(user: user);
        if (portal == Portal.staff) {
          // A student who picked "Staff" stays on sign in, which shows why.
          return user.role == UserRole.staff
              ? const StaffShell()
              : const SignInScreen();
        }
        return const MainShell();
      },
    );
  }
}
