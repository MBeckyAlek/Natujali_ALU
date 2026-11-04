import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../models/report.dart';
import '../../models/report_filter.dart';
import '../../providers/auth_providers.dart';
import '../../providers/report_providers.dart';
import '../../widgets/button_spinner.dart';
import '../../widgets/field_label.dart';
import '../../widgets/info_banner.dart';
import '../../widgets/screen_header.dart';
import '../reports/report_details_screen.dart';
import 'category_grid.dart';
import 'photo_picker_field.dart';
import 'report_received_screen.dart';

/// Single-page form for reporting a new incident, or editing one of the
/// student's own reports when [existing] is given.
class ReportFormScreen extends ConsumerStatefulWidget {
  const ReportFormScreen({super.key, this.existing});

  final Report? existing;

  static Future<void> open(BuildContext context, {Report? existing}) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ReportFormScreen(existing: existing)),
    );
  }

  @override
  ConsumerState<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends ConsumerState<ReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _titleController = TextEditingController(
    text: widget.existing?.title,
  );
  late final _descriptionController = TextEditingController(
    text: widget.existing?.description,
  );
  late final _landmarkController = TextEditingController(
    text: widget.existing?.landmark,
  );
  late ReportCategory? _category = widget.existing?.category;
  late String? _building = widget.existing?.building;
  late String? _photoPath = widget.existing?.photoPath;
  bool _confirmedAccurate = false;
  bool _submitAttempted = false;
  bool _isSubmitting = false;

  bool get _isEditing => widget.existing != null;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitAttempted = true);
    final fieldsValid = _formKey.currentState!.validate();
    final category = _category;
    final needsConfirmation = !_isEditing && !_confirmedAccurate;
    if (!fieldsValid || category == null || needsConfirmation) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final input = ReportInput(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: category,
      building: _building!,
      landmark: _landmarkController.text.trim(),
      photoPath: _photoPath,
    );

    setState(() => _isSubmitting = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final repository = ref.read(reportRepositoryProvider);
      if (_isEditing) {
        await repository.updateReport(widget.existing!.id, input);
        navigator.pop();
        messenger.showSnackBar(
          const SnackBar(content: Text('Report updated.')),
        );
      } else {
        final report = await repository.createReport(input, reporter: user);
        navigator.pushReplacement(
          MaterialPageRoute(
            builder: (_) => ReportReceivedScreen(report: report),
          ),
        );
      }
    } catch (_) {
      // Inputs stay in the form so the student can simply try again.
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            "We couldn't send your report. Check your connection and try again.",
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allReports = ref.watch(reportsProvider).value ?? const [];
    final similar = _category == null || _building == null
        ? const <Report>[]
        : findSimilarOpenReports(
            allReports,
            category: _category!,
            building: _building!,
            excludeId: widget.existing?.id,
          );

    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              ScreenHeader(
                eyebrow: _isEditing ? widget.existing!.reference : 'New report',
                title: _isEditing ? 'Edit report' : 'Report an incident',
                showBack: true,
              ),
              const FieldLabel('Category *'),
              CategoryGrid(
                selected: _category,
                onSelected: (category) => setState(() => _category = category),
              ),
              if (_submitAttempted && _category == null)
                const _ErrorText(
                  'Choose the category that best fits the issue.',
                ),
              const FieldLabel('Title *'),
              TextFormField(
                controller: _titleController,
                maxLength: 80,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Briefly describe the issue…',
                ),
                validator: Validators.reportTitle,
              ),
              const FieldLabel(
                'Description *',
                trailing: 'Minimum 20 characters',
              ),
              TextFormField(
                controller: _descriptionController,
                maxLength: 1000,
                minLines: 4,
                maxLines: 8,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'What happened, when, and who is affected?',
                ),
                validator: Validators.reportDescription,
              ),
              const FieldLabel('Building or area *'),
              DropdownButtonFormField<String>(
                initialValue: _building,
                hint: const Text('Choose a location'),
                items: [
                  for (final building in campusBuildings)
                    DropdownMenuItem(value: building, child: Text(building)),
                ],
                onChanged: (value) => setState(() => _building = value),
                validator: (value) =>
                    value == null ? 'Choose where the issue is.' : null,
              ),
              const FieldLabel('Room or landmark', trailing: 'Optional'),
              TextFormField(
                controller: _landmarkController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'e.g. Washroom beside Lab G02',
                ),
              ),
              if (similar.isNotEmpty) ...[
                const SizedBox(height: 16),
                InfoBanner(
                  icon: Icons.content_copy_outlined,
                  title:
                      'Similar open ${similar.length == 1 ? 'report' : 'reports'} here',
                  message:
                      '${similar.first.reference} · ${similar.first.title}. '
                      'If it is the same issue, follow that report instead of submitting a duplicate.',
                  actionLabel: 'View ${similar.first.reference}',
                  onAction: () =>
                      ReportDetailsScreen.open(context, similar.first.id),
                ),
              ],
              const FieldLabel('Photo', trailing: 'Optional'),
              PhotoPickerField(
                photoPath: _photoPath,
                onChanged: (path) => setState(() => _photoPath = path),
              ),
              const SizedBox(height: 12),
              const InfoBanner(
                message:
                    'Protect privacy: avoid faces, student IDs and personal information. '
                    'Only attach photos relevant to the issue.',
              ),
              const SizedBox(height: 12),
              const InfoBanner(
                tone: BannerTone.warning,
                icon: Icons.health_and_safety_outlined,
                title: 'Not for emergencies',
                message:
                    'Immediate danger? Contact campus security directly. '
                    'Do not wait for a report response.',
              ),
              if (!_isEditing) ...[
                const SizedBox(height: 8),
                CheckboxListTile(
                  value: _confirmedAccurate,
                  onChanged: (value) =>
                      setState(() => _confirmedAccurate = value ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text(
                    'The information is accurate and the photo contains no personal information.',
                    style: TextStyle(fontSize: 13),
                  ),
                  subtitle: _submitAttempted && !_confirmedAccurate
                      ? const _ErrorText('Please confirm before submitting.')
                      : null,
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                // Disabled while sending so a double tap can't create two reports.
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const ButtonSpinner()
                    : const Icon(Icons.send_outlined),
                label: Text(
                  _isSubmitting
                      ? 'Submitting report…'
                      : (_isEditing ? 'Save changes' : 'Submit report'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        message,
        style: const TextStyle(color: AppColors.accent, fontSize: 12),
      ),
    );
  }
}
