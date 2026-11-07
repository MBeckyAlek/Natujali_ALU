import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../data/auth_repository.dart';
import '../../providers/auth_providers.dart';
import '../../providers/session_providers.dart';
import '../../widgets/button_spinner.dart';
import '../../widgets/field_label.dart';
import '../../widgets/info_banner.dart';
import '../../widgets/password_field.dart';
import '../../widgets/screen_header.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _agreed = false;
  bool _submitAttempted = false;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _studentIdController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() => _submitAttempted = true);
    final isValid = _formKey.currentState!.validate();
    if (!isValid || !_agreed) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await ref
          .read(sessionProvider.notifier)
          .start(Portal.student, remember: false);
      await ref
          .read(authRepositoryProvider)
          .register(
            fullName: _nameController.text,
            email: _emailController.text,
            studentId: _studentIdController.text,
            password: _passwordController.text,
          );
      // Return to the root so AuthGate can show the verify-email screen.
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const ScreenHeader(
                eyebrow: 'Student registration',
                title: 'Join your campus',
                showBack: true,
              ),
              Text(
                'Create a student account with your ALU email. '
                'Staff access is invitation-only.',
                style: TextStyle(color: context.colors.muted),
              ),
              const FieldLabel('Full name'),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                decoration: const InputDecoration(
                  hintText: 'e.g. Amina Hassan',
                ),
                validator: (value) =>
                    Validators.required(value, 'Enter your full name.'),
              ),
              const FieldLabel('University email'),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  hintText: 'name@alustudent.com',
                  helperText:
                      "We'll send a link to verify it after you sign up.",
                ),
                validator: Validators.studentEmail,
              ),
              const FieldLabel('Student ID'),
              TextFormField(
                controller: _studentIdController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  hintText: 'e.g. ALU-2024-0816',
                ),
                validator: (value) =>
                    Validators.required(value, 'Enter your student ID.'),
              ),
              const FieldLabel('Password'),
              PasswordField(
                controller: _passwordController,
                validator: Validators.password,
              ),
              const FieldLabel('Confirm password'),
              PasswordField(
                controller: _confirmController,
                validator: (value) => value == _passwordController.text
                    ? null
                    : "Passwords don't match.",
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _agreed,
                onChanged: (value) => setState(() => _agreed = value ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                  'I agree to the Terms of Use and Privacy Policy, including responsible reporting.',
                  style: TextStyle(fontSize: 13),
                ),
                subtitle: _submitAttempted && !_agreed
                    ? Text(
                        'Please accept the terms to continue.',
                        style: TextStyle(
                          color: context.colors.primary,
                          fontSize: 12,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 12),
              if (_error != null) ...[
                InfoBanner(title: "Couldn't create account", message: _error!),
                const SizedBox(height: 12),
              ],
              FilledButton(
                onPressed: _isLoading ? null : _register,
                child: _isLoading
                    ? const ButtonSpinner()
                    : const Text('Create account'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Already registered? Sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
