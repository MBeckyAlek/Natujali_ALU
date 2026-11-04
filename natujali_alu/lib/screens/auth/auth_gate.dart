import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_providers.dart';
import '../shell/main_shell.dart';
import 'sign_in_screen.dart';
import 'verify_email_screen.dart';

/// Decides which part of the app to show based on the auth state:
/// signed out → sign in, unverified → verify email, otherwise → the app.
///
/// Because it watches [authStateProvider], signing in or out anywhere in the
/// app automatically swaps the screen here.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => const SignInScreen(),
      data: (user) {
        if (user == null) return const SignInScreen();
        if (!user.emailVerified) return VerifyEmailScreen(user: user);
        return const MainShell();
      },
    );
  }
}
