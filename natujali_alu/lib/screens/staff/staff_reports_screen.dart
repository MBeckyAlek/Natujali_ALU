import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/report.dart';
import '../../models/report_filter.dart';
import '../../providers/report_providers.dart';
import '../../providers/staff_providers.dart';
import '../../widgets/choice_pill.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/report_card.dart';
import '../../widgets/screen_header.dart';
import 'review_incident_screen.dart';

final _shortDate = DateFormat('d MMM');

/// The full staff queue: search, status tabs, and filters for category,
/// team, building, month and submission date.
class StaffReportsScreen extends ConsumerStatefulWidget {
  const StaffReportsScreen({super.key});

  @override
  ConsumerState<StaffReportsScreen> createState() => _StaffReportsScreenState();
}

class _StaffReportsScreenState extends ConsumerState<StaffReportsScreen> {
  String _query = '';

  StaffQueueFilterNotifier get _filters =>
      ref.read(staffQueueFilterProvider.notifier);

  Future<void> _pickCategory(ReportCategory? current) async {
    final picked = await _pickOption(
      context,
      title: 'Category',
      options: ReportCategory.values,
      current: current,
      labelOf: (category) => category.label,
    );
    if (picked != null) _filters.setCategory(picked.$1);
  }

  Future<void> _pickPriority(ReportPriority? current) async {
    final picked = await _pickOption(
      context,
      title: 'Priority',
      options: ReportPriority.values,
      current: current,
      labelOf: (priority) => priority.label,
    );
    if (picked != null) _filters.setPriority(picked.$1);
  }

  Future<void> _pickTeam(String? current) async {
    final picked = await _pickOption(
      context,
      title: 'Assigned team',
      options: campusTeams,
      current: current,
      labelOf: (team) => team,
    );
    if (picked != null) _filters.setTeam(picked.$1);
  }

  Future<void> _pickBuilding(String? current) async {
    final picked = await _pickOption(
      context,
      title: 'Building',
      options: campusBuildings,
      current: current,
      labelOf: (building) => building,
    );
    if (picked != null) _filters.setBuilding(picked.$1);
  }

  Future<void> _pickMonth(DateTime? current, List<Report> all) async {
    final picked = await _pickOption(
      context,
      title: 'Month submitted',
      options: reportMonths(all),
      current: current,
      labelOf: formatMonth,
    );
    if (picked != null) _filters.setMonth(picked.$1);
  }

  Future<void> _pickDates(StaffQueueFilter filter) async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      initialDateRange: filter.from != null && filter.to != null
          ? DateTimeRange(start: filter.from!, end: filter.to!)
          : null,
      helpText: 'Submitted between',
    );
    if (range != null) _filters.setDates(range.start, range.end);
  }

  @override
  Widget build(BuildContext context) {
    final reports = ref.watch(reportsProvider);
    final filter = ref.watch(staffQueueFilterProvider);

    return SafeArea(
      child: RefreshIndicator(
        // Data is live already; this just reassures people who pull to refresh.
        onRefresh: () => ref.refresh(reportsProvider.future),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const ScreenHeader(eyebrow: 'Campus operations', title: 'Reports'),
            TextField(
              onChanged: (value) => setState(() => _query = value),
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Search title, location or reference',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final tab in QueueTab.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoicePill(
                        label: tab.label,
                        selected: tab == filter.tab,
                        onTap: () => _filters.selectTab(tab),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                spacing: 8,
                children: [
                  _FilterButton(
                    icon: Icons.category_outlined,
                    label: filter.category?.label ?? 'Category',
                    active: filter.category != null,
                    onTap: () => _pickCategory(filter.category),
                  ),
                  FilterChip(
                    label: const Text('Overdue'),
                    selected: filter.overdueOnly,
                    onSelected: _filters.setOverdueOnly,
                  ),
                  _FilterButton(
                    icon: Icons.flag_outlined,
                    label: filter.priority?.label ?? 'Priority',
                    active: filter.priority != null,
                    onTap: () => _pickPriority(filter.priority),
                  ),
                  _FilterButton(
                    icon: Icons.groups_outlined,
                    label: filter.team ?? 'Team',
                    active: filter.team != null,
                    onTap: () => _pickTeam(filter.team),
                  ),
                  _FilterButton(
                    icon: Icons.apartment_outlined,
                    label: filter.building ?? 'Building',
                    active: filter.building != null,
                    onTap: () => _pickBuilding(filter.building),
                  ),
                  _FilterButton(
                    icon: Icons.calendar_month_outlined,
                    label: filter.month != null
                        ? formatMonth(filter.month!)
                        : 'Month',
                    active: filter.month != null,
                    onTap: () =>
                        _pickMonth(filter.month, reports.value ?? const []),
                  ),
                  _FilterButton(
                    icon: Icons.date_range_outlined,
                    label:
                        filter.from != null &&
                            filter.to != null &&
                            filter.month == null
                        ? '${_shortDate.format(filter.from!)} – ${_shortDate.format(filter.to!)}'
                        : 'Dates',
                    active: filter.from != null && filter.month == null,
                    onTap: () => _pickDates(filter),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            reports.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => const EmptyState(
                icon: Icons.cloud_off_outlined,
                title: "Couldn't load reports",
                message: 'Check your connection and try again.',
              ),
              data: (all) => _buildList(all, filter),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<Report> all, StaffQueueFilter filter) {
    final visible = filter.tab.sort(
      ReportFilter(query: _query).apply(all.where(filter.matches).toList()),
    );
    final isFiltered = _query.isNotEmpty || filter.hasExtras;

    if (visible.isEmpty) {
      return EmptyState(
        icon: Icons.inbox_outlined,
        title: isFiltered ? 'No matching reports' : 'Nothing here',
        message: isFiltered
            ? 'Try a different keyword or clear the filters.'
            : 'No ${filter.tab.label.toLowerCase()} reports right now.',
        actionLabel: filter.hasExtras ? 'Clear filters' : null,
        onAction: filter.hasExtras ? _filters.clearExtras : null,
      );
    }

    final newestFirst = filter.tab.newestFirst;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${visible.length} ${visible.length == 1 ? 'report' : 'reports'} · '
                '${newestFirst ? 'recently updated first' : 'most urgent first'}',
                style: TextStyle(color: context.colors.muted, fontSize: 13),
              ),
            ),
            if (filter.hasExtras)
              TextButton(
                onPressed: _filters.clearExtras,
                child: const Text('Clear filters'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        for (final report in visible)
          ReportCard(
            report: report,
            forStaff: true,
            onTap: () => ReviewIncidentScreen.open(context, report.id),
          ),
      ],
    );
  }
}

/// Small outlined button that shows a filter's current value.
class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final foreground = active ? c.primary : c.ink;
    return Material(
      color: active ? c.primaryTint : c.surface,
      shape: StadiumBorder(
        side: BorderSide(color: active ? c.primary : c.border),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: foreground),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(Icons.arrow_drop_down, size: 18, color: foreground),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet with "Any" plus [options]. Returns the choice wrapped in a
/// record, so "Any" (null) can be told apart from closing the sheet.
Future<(T?,)?> _pickOption<T>(
  BuildContext context, {
  required String title,
  required List<T> options,
  required T? current,
  required String Function(T) labelOf,
}) {
  return showModalBottomSheet<(T?,)>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          for (final option in [null, ...options])
            ListTile(
              title: Text(option == null ? 'Any' : labelOf(option)),
              trailing: option == current
                  ? Icon(Icons.check, color: context.colors.primary)
                  : null,
              onTap: () => Navigator.of(context).pop((option,)),
            ),
        ],
      ),
    ),
  );
}
