import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/report.dart';
import '../../models/report_filter.dart';
import '../../providers/report_providers.dart';
import '../../widgets/choice_pill.dart';
import '../../widgets/field_label.dart';
import '../../widgets/info_banner.dart';
import '../../widgets/screen_header.dart';

/// Lets the student pick categories, statuses, a building and a month. Choices are
/// kept locally until "Show N reports" applies them to the shared filter.
class FilterReportsScreen extends ConsumerStatefulWidget {
  const FilterReportsScreen({super.key});

  @override
  ConsumerState<FilterReportsScreen> createState() =>
      _FilterReportsScreenState();
}

class _FilterReportsScreenState extends ConsumerState<FilterReportsScreen> {
  late final ReportFilter _initial = ref.read(campusFilterProvider);
  late final Set<ReportCategory> _categories = {..._initial.categories};
  late final Set<ReportStatus> _statuses = {..._initial.statuses};
  late String? _building = _initial.building;
  late DateTime? _month = _initial.month;

  ReportFilter get _draft => ReportFilter(
    query: _initial.query,
    categories: _categories,
    statuses: _statuses,
    building: _building,
    month: _month,
  );

  void _toggle<T>(Set<T> set, T value) {
    setState(() => set.contains(value) ? set.remove(value) : set.add(value));
  }

  void _apply() {
    ref.read(campusFilterProvider.notifier).replace(_draft);
    Navigator.of(context).pop();
  }

  void _clearAll() {
    setState(() {
      _categories.clear();
      _statuses.clear();
      _building = null;
      _month = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final allReports = ref.watch(reportsProvider).value ?? const [];
    final matchCount = _draft.apply(allReports).length;
    // Keep the chosen month listed even if its reports have since gone.
    final months = reportMonths(allReports);
    if (_month != null && !months.contains(_month)) months.insert(0, _month!);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const ScreenHeader(
              eyebrow: 'Explore',
              title: 'Filter reports',
              showBack: true,
            ),
            Text(
              'Narrow the list to the issues that matter to you.',
              style: TextStyle(color: context.colors.muted),
            ),
            const SizedBox(height: 20),
            Text('Category', style: textTheme.titleMedium),
            Text(
              'Choose multiple',
              style: TextStyle(color: context.colors.muted, fontSize: 12),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final category in ReportCategory.values)
                  ChoicePill(
                    label: category.label,
                    selected: _categories.contains(category),
                    onTap: () => _toggle(_categories, category),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Status', style: textTheme.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final status in ReportStatus.values)
                  ChoicePill(
                    label: status.label,
                    selected: _statuses.contains(status),
                    onTap: () => _toggle(_statuses, status),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const FieldLabel('Building'),
            DropdownButtonFormField<String?>(
              initialValue: _building,
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All buildings'),
                ),
                for (final building in campusBuildings)
                  DropdownMenuItem(value: building, child: Text(building)),
              ],
              onChanged: (value) => setState(() => _building = value),
            ),
            const FieldLabel('Month submitted'),
            DropdownButtonFormField<DateTime?>(
              initialValue: _month,
              items: [
                const DropdownMenuItem(value: null, child: Text('Any month')),
                for (final month in months)
                  DropdownMenuItem(
                    value: month,
                    child: Text(formatMonth(month)),
                  ),
              ],
              onChanged: (value) => setState(() => _month = value),
            ),
            const SizedBox(height: 20),
            InfoBanner(
              message:
                  '$matchCount ${matchCount == 1 ? 'report matches' : 'reports match'} '
                  'your selection. Filters apply to campus reports, not your notifications.',
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _apply,
              child: Text(
                'Show $matchCount ${matchCount == 1 ? 'report' : 'reports'}',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _clearAll,
              child: const Text('Clear all filters'),
            ),
          ],
        ),
      ),
    );
  }
}
