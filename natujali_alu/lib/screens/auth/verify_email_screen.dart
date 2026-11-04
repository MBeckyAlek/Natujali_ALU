import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/app_user.dart';
import '../../providers/auth_providers.dart';
import '../../widgets/button_spinner.dart';
import '../../widgets/info_banner.dart';

/// Shown after registration until the student clicks the link in their
/// verification email. Only verified ALU emails can use the app.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key, required this.user});

  final AppUser user;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _isChecking = false;

  Future<void> _checkVerified() async {
    setState(() => _isChecking = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(authRepositoryProvider).reloadUser();
      // If verified, AuthGate moves on to the home screen by itself.
      if (!mounted) return;
      if (ref.read(currentUserProvider)?.emailVerified != true) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Not verified yet. Open the link in your email, then try again.',
            ),
          ),
        );
      }
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Couldn't check right now. Try again.")),
      );
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _resend() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(authRepositoryProvider).resendVerificationEmail();
      messenger.showSnackBar(
        const SnackBar(content: Text('Verification email sent.')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            "Couldn't send the email. Wait a minute and try again.",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 40),
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: AppColors.crimsonCard,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_unread_outlined,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Verify your ALU email',
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'We sent a verification link to\n${widget.user.email}.\n'
              'Open it, then come back here.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 24),
            const InfoBanner(
              message:
                  'Verification confirms you are an ALU student. '
                  "Can't find it? Check your spam folder.",
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isChecking ? null : _checkVerified,
              child: _isChecking
                  ? const ButtonSpinner()
                  : const Text("I've verified my email"),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _resend,
              child: const Text('Resend email'),
            ),
            TextButton(
              onPressed: () => ref.read(authRepositoryProvider).signOut(),
              child: const Text('Use a different account'),
            ),
          ],
        ),
      ),
    );
  }
}
