import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../data/auth_repository.dart';
import '../../providers/auth_providers.dart';
import '../../widgets/button_spinner.dart';
import '../../widgets/field_label.dart';
import '../../widgets/info_banner.dart';
import '../../widgets/password_field.dart';
import 'register_screen.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .signIn(
            email: _emailController.text,
            password: _passwordController.text,
          );
      // AuthGate swaps to the home screen when the auth state changes.
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(
        () => _error =
            'Something went wrong. Check your connection and try again.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showResetPassword() async {
    final email = await showDialog<String>(
      context: context,
      builder: (_) => _ResetPasswordDialog(initialEmail: _emailController.text),
    );
    if (email == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(email);
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'If an account exists for that email, a reset link is on its way.',
          ),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text("Couldn't send the reset email. Try again."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'AFRICAN LEADERSHIP UNIVERSITY',
                style: textTheme.labelSmall,
              ),
              Text('Natujali', style: textTheme.headlineSmall),
              const SizedBox(height: 16),
              const _WelcomeCard(),
              const SizedBox(height: 24),
              Text('Welcome back', style: textTheme.titleLarge),
              const FieldLabel('University email'),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  hintText: 'name@alustudent.com',
                  suffixIcon: Icon(Icons.mail_outline),
                ),
                validator: Validators.aluEmail,
              ),
              const FieldLabel('Password'),
              PasswordField(
                controller: _passwordController,
                validator: (value) =>
                    Validators.required(value, 'Enter your password.'),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  onPressed: _showResetPassword,
                  child: const Text('Forgot password?'),
                ),
              ),
              if (_error != null) ...[
                InfoBanner(title: 'Sign in failed', message: _error!),
                const SizedBox(height: 12),
              ],
              FilledButton.icon(
                onPressed: _isLoading ? null : _signIn,
                icon: _isLoading
                    ? const ButtonSpinner()
                    : const Icon(Icons.arrow_forward),
                label: Text(_isLoading ? 'Signing in…' : 'Sign in'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _isLoading
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      ),
                child: const Text('Create student account'),
              ),
              const SizedBox(height: 20),
              const InfoBanner(
                message:
                    'Campus staff use their provisioned @alueducation.com account. '
                    'Staff access is assigned by an administrator.',
              ),
              const SizedBox(height: 16),
              Text(
                'By continuing, you agree to our Terms & Privacy Policy.',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();

  @override
  Widget build(BuildContext context) {
    // Navy card with a red bar, echoing the ALU logo.
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.account_balance_outlined,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'A better campus,\none report at a time.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Container(width: 48, height: 4, color: AppColors.accent),
          const SizedBox(height: 12),
          Text(
            'Spot an issue. Share it in minutes. Follow every step toward a fix.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Icon(Icons.shield_outlined, size: 16, color: Colors.white),
              SizedBox(width: 6),
              Text(
                'Your campus. A shared responsibility.',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResetPasswordDialog extends StatefulWidget {
  const _ResetPasswordDialog({required this.initialEmail});

  final String initialEmail;

  @override
  State<_ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<_ResetPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _controller = TextEditingController(text: widget.initialEmail);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reset password'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(hintText: 'name@alustudent.com'),
          validator: Validators.aluEmail,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, _controller.text.trim());
            }
          },
          child: const Text('Send link'),
        ),
      ],
    );
  }
}
