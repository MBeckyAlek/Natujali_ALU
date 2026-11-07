import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/error_messages.dart';
import '../../core/utils/formatters.dart';
import '../../models/announcement.dart';
import '../../models/report.dart';
import '../../providers/announcement_providers.dart';
import '../../providers/auth_providers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/button_spinner.dart';
import '../../widgets/choice_pill.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/field_label.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/section_header.dart';

/// Staff post short notices about known issues, e.g. planned water cuts.
/// Students see them on Home and while reporting in that building.
class AnnouncementsScreen extends ConsumerWidget {
  const AnnouncementsScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AnnouncementsScreen()));
  }

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    Announcement announcement,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Take this down?'),
        content: Text('"${announcement.title}" will disappear for students.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Take down'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(announcementRepositoryProvider).remove(announcement.id);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(describeError(e, action: 'take it down'))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcements = ref.watch(activeAnnouncementsProvider);
    final now = DateTime.now();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const ScreenHeader(
              eyebrow: 'Campus operations',
              title: 'Announcements',
              showBack: true,
            ),
            const _AnnouncementForm(),
            const SectionHeader(title: 'Active now'),
            announcements.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const EmptyState(
                icon: Icons.cloud_off_outlined,
                title: "Couldn't load announcements",
                message: 'Check your connection and try again.',
              ),
              data: (items) {
                final active = items.where((a) => a.isActive(now)).toList();
                if (active.isEmpty) {
                  return const EmptyState(
                    icon: Icons.campaign_outlined,
                    title: 'Nothing posted',
                    message: 'Active announcements will appear here.',
                  );
                }
                return Column(
                  children: [
                    for (final announcement in active)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AppCard(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      announcement.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (announcement.message.isNotEmpty)
                                      Text(announcement.message),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${announcement.audience} · until '
                                      '${formatShortDateTime(announcement.expiresAt)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Take down',
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: context.colors.muted,
                                ),
                                onPressed: () =>
                                    _confirmRemove(context, ref, announcement),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementForm extends ConsumerStatefulWidget {
  const _AnnouncementForm();

  @override
  ConsumerState<_AnnouncementForm> createState() => _AnnouncementFormState();
}

class _AnnouncementFormState extends ConsumerState<_AnnouncementForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String? _building;
  AnnouncementDuration _duration = AnnouncementDuration.sixHours;
  bool _isPosting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isPosting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(announcementRepositoryProvider)
          .post(
            title: _titleController.text.trim(),
            message: _messageController.text.trim(),
            building: _building,
            postedBy:
                ref.read(currentUserProvider)?.fullName ?? 'Campus operations',
            duration: _duration.duration,
          );
      _titleController.clear();
      _messageController.clear();
      messenger.showSnackBar(
        const SnackBar(content: Text('Announcement posted to students.')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(describeError(e, action: 'post the announcement')),
        ),
      );
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const FieldLabel('Headline *'),
          TextFormField(
            controller: _titleController,
            maxLength: 80,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'e.g. Water off on the 2nd floor, 2–4 pm',
            ),
            validator: (value) => (value?.trim().isEmpty ?? true)
                ? 'Add a short headline.'
                : null,
          ),
          const FieldLabel('Details', trailing: 'Optional'),
          TextFormField(
            controller: _messageController,
            maxLength: 500,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'What is happening and what students should do.',
            ),
          ),
          const FieldLabel('Where'),
          DropdownButtonFormField<String?>(
            isExpanded: true,
            initialValue: _building,
            items: [
              const DropdownMenuItem(value: null, child: Text('Whole campus')),
              for (final building in campusBuildings)
                DropdownMenuItem(value: building, child: Text(building)),
            ],
            onChanged: (value) => setState(() => _building = value),
          ),
          const FieldLabel('Show for'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final duration in AnnouncementDuration.values)
                ChoicePill(
                  label: duration.label,
                  selected: duration == _duration,
                  onTap: () => setState(() => _duration = duration),
                ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _isPosting ? null : _post,
            icon: _isPosting
                ? const ButtonSpinner()
                : const Icon(Icons.campaign_outlined),
            label: Text(_isPosting ? 'Posting…' : 'Post announcement'),
          ),
        ],
      ),
    );
  }
}
