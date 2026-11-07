import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../data/auth_repository.dart';
import '../../models/app_user.dart';
import '../../providers/auth_providers.dart';
import '../../providers/session_providers.dart';
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
  late Portal _portal = ref.read(sessionProvider);
  bool _rememberMe = false;
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
          .read(sessionProvider.notifier)
          .start(_portal, remember: _rememberMe);
      final user = await ref
          .read(authRepositoryProvider)
          .signIn(
            email: _emailController.text,
            password: _passwordController.text,
          );
      // Staff may use either portal; students only the student one.
      if (_portal == Portal.staff && user.role != UserRole.staff) {
        await ref.read(sessionProvider.notifier).end();
        setState(
          () => _error =
              "This account doesn't have staff access. Sign in as a student, "
              'or ask an administrator to add you as staff.',
        );
      }
      // Otherwise AuthGate swaps to the right app when the auth state changes.
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
    final isStaff = _portal == Portal.staff;

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
              const SizedBox(height: 12),
              SegmentedButton<Portal>(
                segments: const [
                  ButtonSegment(
                    value: Portal.student,
                    label: Text('Student'),
                    icon: Icon(Icons.school_outlined),
                  ),
                  ButtonSegment(
                    value: Portal.staff,
                    label: Text('Staff'),
                    icon: Icon(Icons.badge_outlined),
                  ),
                ],
                selected: {_portal},
                onSelectionChanged: _isLoading
                    ? null
                    : (selection) => setState(() {
                        _portal = selection.single;
                        _error = null;
                      }),
              ),
              const FieldLabel('University email'),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: InputDecoration(
                  hintText: isStaff
                      ? 'name@alueducation.com'
                      : 'name@alustudent.com',
                  suffixIcon: const Icon(Icons.mail_outline),
                ),
                validator: Validators.aluEmail,
              ),
              const FieldLabel('Password'),
              PasswordField(
                controller: _passwordController,
                validator: (value) =>
                    Validators.required(value, 'Enter your password.'),
              ),
              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    onChanged: (value) =>
                        setState(() => _rememberMe = value ?? false),
                  ),
                  const Expanded(child: Text('Keep me signed in')),
                  TextButton(
                    onPressed: _showResetPassword,
                    child: const Text('Forgot password?'),
                  ),
                ],
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
                label: Text(
                  _isLoading ? 'Signing in…' : 'Sign in as ${_portal.label}',
                ),
              ),
              const SizedBox(height: 12),
              if (!isStaff)
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
              InfoBanner(
                message: isStaff
                    ? 'Campus staff use their provisioned @alueducation.com account. '
                          'Staff access is assigned by an administrator.'
                    : 'Without "Keep me signed in", you will be asked to sign in '
                          'again each time the app is opened.',
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
    // Campus photo with a dark fade at the bottom so the caption stays
    // readable in both themes.
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 240,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/campus.jpg',
              fit: BoxFit.cover,
              alignment: const Alignment(0, 0.1),
              semanticLabel: 'ALU campus courtyard at dusk',
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.5, 1],
                  colors: [Colors.transparent, Colors.black87],
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 16,
              child: Row(
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    size: 18,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Our campus, our responsibility',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  Container(width: 32, height: 4, color: context.colors.accent),
                ],
              ),
            ),
          ],
        ),
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
