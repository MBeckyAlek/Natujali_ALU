import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/app_user.dart';
import '../../providers/auth_providers.dart';
import '../../providers/session_providers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/info_banner.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/theme_mode_selector.dart';
import '../notifications/notifications_screen.dart';
import '../reports/my_reports_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _sendPasswordReset(
    BuildContext context,
    WidgetRef ref,
    String email,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(email);
      messenger.showSnackBar(
        SnackBar(content: Text('Password reset link sent to $email.')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Couldn't send the email. Try again.")),
      );
    }
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You will need your ALU email and password to sign back in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    // AuthGate returns to the sign-in screen once the user is signed out.
    if (confirmed == true) await ref.read(sessionProvider.notifier).end();
  }

  void _showSafetyInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Help & campus security'),
        content: const Text(
          'Natujali is for non-emergency campus issues. If anyone is in immediate '
          'danger, contact campus security or emergency services right away.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();
    final isStaff = user.role == UserRole.staff;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const ScreenHeader(eyebrow: 'Profile', title: 'Your account'),
          _ProfileCard(user: user),
          const SizedBox(height: 24),
          Text('Account', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                // Staff don't file reports, so they skip the student rows.
                if (!isStaff) ...[
                  _MenuTile(
                    icon: Icons.assignment_outlined,
                    label: 'My reports',
                    onTap: () => MyReportsScreen.open(context),
                  ),
                  const Divider(),
                  _MenuTile(
                    icon: Icons.notifications_none,
                    label: 'Notifications',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    ),
                  ),
                  const Divider(),
                ],
                _MenuTile(
                  icon: Icons.lock_outline,
                  label: 'Reset password',
                  onTap: () => _sendPasswordReset(context, ref, user.email),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Appearance', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const ThemeModeSelector(),
          const SizedBox(height: 16),
          InfoBanner(
            title: 'Your account role',
            message: isStaff
                ? 'Staff access lets you review reports and update their status.'
                : 'Student access lets you submit and track reports. '
                      'Only university administrators can authorise campus staff.',
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => _showSafetyInfo(context),
              child: const Text('Help & campus security'),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _confirmSignOut(context, ref),
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
          ),
          const SizedBox(height: 16),
          Text(
            'Natujali · Version 1.0',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final muted = TextStyle(color: context.colors.muted, fontSize: 13);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: context.colors.primaryTint,
                child: Text(
                  user.initials,
                  style: TextStyle(
                    color: context.colors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (user.studentId.isNotEmpty)
                      Text(user.studentId, style: muted),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: context.colors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_outlined,
                            size: 14,
                            color: context.colors.greenText,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${user.role == UserRole.staff ? 'Staff' : 'Student'} · Verified',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(user.email, style: muted),
          const SizedBox(height: 4),
          Text('African Leadership University', style: muted),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: context.colors.primary),
      title: Text(label),
      trailing: Icon(Icons.chevron_right, color: context.colors.muted),
      onTap: onTap,
    );
  }
}
