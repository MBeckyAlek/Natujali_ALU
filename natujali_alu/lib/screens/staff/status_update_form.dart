import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/error_messages.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../models/report.dart';
import '../../providers/report_providers.dart';
import '../../widgets/button_spinner.dart';
import '../../widgets/choice_pill.dart';
import '../../widgets/field_label.dart';

/// Lets staff pick the next status, assign a team and leave a note for the
/// student. Every save adds one entry to the report's history.
class StatusUpdateForm extends ConsumerStatefulWidget {
  const StatusUpdateForm({super.key, required this.report});

  final Report report;

  @override
  ConsumerState<StatusUpdateForm> createState() => _StatusUpdateFormState();
}

class _StatusUpdateFormState extends ConsumerState<StatusUpdateForm> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();
  late ReportStatus _status = _suggestedNext(widget.report.status);
  // Only preselect teams the dropdown knows, in case old data uses another name.
  late String? _team = campusTeams.contains(widget.report.assignedTeam)
      ? widget.report.assignedTeam
      : null;
  late ReportPriority _priority = widget.report.priority;
  bool _isSaving = false;

  /// Preselect the next step, since that is what staff usually want.
  static ReportStatus _suggestedNext(ReportStatus current) {
    const steps = ReportStatus.values;
    return steps[(current.index + 1).clamp(0, steps.length - 1)];
  }

  static String _hintFor(ReportStatus status) {
    return switch (status) {
      ReportStatus.submitted => 'e.g. Reopened: the issue has come back.',
      ReportStatus.underReview =>
        'e.g. Thanks, we have seen this and are checking the area.',
      ReportStatus.inProgress =>
        'e.g. A technician is scheduled for tomorrow morning.',
      ReportStatus.resolved => 'e.g. The tap was replaced and tested.',
    };
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(reportRepositoryProvider)
          .updateStatus(
            widget.report.id,
            status: _status,
            note: _noteController.text.trim(),
            assignedTeam: _team,
            priority: _priority,
          );
      _noteController.clear();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${widget.report.reference} is now ${_status.label}. '
            'The student has been notified.',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(describeError(e, action: 'save the update'))),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const FieldLabel('New status *'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final status in ReportStatus.values)
                ChoicePill(
                  label: status.label,
                  selected: status == _status,
                  onTap: () => setState(() => _status = status),
                ),
            ],
          ),
          FieldLabel(
            'Priority',
            trailing: 'Resolve within ${formatDuration(_priority.target)}',
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final priority in ReportPriority.values)
                ChoicePill(
                  label: priority.label,
                  selected: priority == _priority,
                  onTap: () => setState(() => _priority = priority),
                ),
            ],
          ),
          const FieldLabel('Assigned team', trailing: 'Optional'),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _team,
            hint: const Text('Choose a team'),
            items: [
              for (final team in campusTeams)
                DropdownMenuItem(value: team, child: Text(team)),
            ],
            onChanged: (value) => setState(() => _team = value),
          ),
          const FieldLabel('Note to the student *'),
          TextFormField(
            controller: _noteController,
            minLines: 3,
            maxLines: 6,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(hintText: _hintFor(_status)),
            validator: Validators.statusNote,
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const ButtonSpinner()
                : const Icon(Icons.check_circle_outline),
            label: Text(_isSaving ? 'Saving…' : 'Save update'),
          ),
        ],
      ),
    );
  }
}
