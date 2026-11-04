import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/report.dart';
import '../../models/report_filter.dart';
import '../../providers/report_providers.dart';
import '../../widgets/choice_pill.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/report_card.dart';
import '../../widgets/screen_header.dart';
import '../report_form/report_form_screen.dart';
import 'filter_reports_screen.dart';
import 'report_details_screen.dart';

const _openStatuses = {
  ReportStatus.submitted,
  ReportStatus.underReview,
  ReportStatus.inProgress,
};

/// Browse every report on campus, with search and filters.
class CampusReportsScreen extends ConsumerStatefulWidget {
  const CampusReportsScreen({super.key});

  @override
  ConsumerState<CampusReportsScreen> createState() =>
      _CampusReportsScreenState();
}

class _CampusReportsScreenState extends ConsumerState<CampusReportsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(campusFilterProvider);
    final filterNotifier = ref.read(campusFilterProvider.notifier);
    final reports = ref.watch(filteredCampusReportsProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ScreenHeader(
            eyebrow: 'Explore',
            title: 'Campus reports',
            trailing: IconButton(
              tooltip: 'Report an issue',
              color: AppColors.primary,
              icon: const Icon(Icons.add),
              onPressed: () => ReportFormScreen.open(context),
            ),
          ),
          const Text(
            "See what's been reported and what's being fixed.",
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            onChanged: filterNotifier.setQuery,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search incidents or report ID',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                tooltip: 'Filters',
                icon: Badge(
                  isLabelVisible: filter.hasFilters,
                  smallSize: 8,
                  child: const Icon(Icons.tune),
                ),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const FilterReportsScreen(),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              ChoicePill(
                label: 'All reports',
                selected: filter.statuses.isEmpty,
                onTap: () => filterNotifier.setStatuses(const {}),
              ),
              ChoicePill(
                label: 'Open',
                selected: setEquals(filter.statuses, _openStatuses),
                onTap: () => filterNotifier.setStatuses(_openStatuses),
              ),
              ChoicePill(
                label: 'Resolved',
                selected: setEquals(filter.statuses, {ReportStatus.resolved}),
                onTap: () =>
                    filterNotifier.setStatuses({ReportStatus.resolved}),
              ),
            ],
          ),
          const SizedBox(height: 16),
          reports.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => const EmptyState(
              icon: Icons.cloud_off_outlined,
              title: "Couldn't load campus reports",
              message: 'Check your connection and try again.',
            ),
            data: (items) => _ReportList(
              reports: items,
              onClearFilters: () {
                _searchController.clear();
                filterNotifier.replace(const ReportFilter());
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportList extends StatelessWidget {
  const _ReportList({required this.reports, required this.onClearFilters});

  final List<Report> reports;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'No matching reports',
        message: 'Try a different keyword or remove a filter.',
        actionLabel: 'Clear search & filters',
        onAction: onClearFilters,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${reports.length} campus ${reports.length == 1 ? 'report' : 'reports'} · newest first',
          style: const TextStyle(color: AppColors.muted, fontSize: 13),
        ),
        const SizedBox(height: 12),
        for (final report in reports)
          ReportCard(
            report: report,
            onTap: () => ReportDetailsScreen.open(context, report.id),
          ),
        const SizedBox(height: 8),
        const Text(
          'Found the same issue? Follow the existing report instead of creating a duplicate.',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ],
    );
  }
}
