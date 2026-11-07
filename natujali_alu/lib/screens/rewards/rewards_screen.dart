import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/achievements.dart';
import '../../models/rewards.dart';
import '../../providers/report_providers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/section_header.dart';
import '../reports/report_details_screen.dart';

/// The student's coins, badges, how to earn them, and every report that
/// has earned coins. Private to the student.
class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const RewardsScreen()));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(coinSummaryProvider);
    final achievements = ref.watch(achievementsProvider);
    final earned = achievements.where((a) => a.earned).length;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const ScreenHeader(
              eyebrow: 'Rewards',
              title: 'Coins & badges',
              showBack: true,
            ),
            CoinBalanceCard(summary: summary),
            SectionHeader(title: 'Badges · $earned of ${achievements.length}'),
            Text(
              'Only you can see your badges.',
              style: TextStyle(color: context.colors.muted, fontSize: 12),
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.25,
              children: [
                for (final achievement in achievements)
                  _BadgeTile(achievement: achievement),
              ],
            ),
            const SectionHeader(title: 'How to earn coins'),
            const _Rule(
              Icons.check_circle_outline,
              '+$coinsPerResolvedReport coins when staff resolve your report',
            ),
            const _Rule(
              Icons.photo_camera_outlined,
              '+$photoBonusCoins bonus if your report included a photo',
            ),
            const _Rule(
              Icons.hourglass_empty,
              'Coins arrive only after the issue is fixed, so accurate '
              'reports pay off',
            ),
            const SectionHeader(title: 'Coin history'),
            if (summary.entries.isEmpty)
              const EmptyState(
                icon: Icons.savings_outlined,
                title: 'No coins yet',
                message: 'Report an issue on campus. You earn coins once staff resolve it.',
              )
            else
              for (final entry in summary.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    onTap: () =>
                        ReportDetailsScreen.open(context, entry.report.id),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.report.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${entry.report.reference} · resolved '
                                '${formatShortDateTime(entry.earnedAt)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '+${entry.coins}',
                          style: TextStyle(
                            color: context.colors.greenText,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

/// Balance plus how many open reports could still earn coins. Shown on
/// Home and at the top of the Rewards screen.
class CoinBalanceCard extends StatelessWidget {
  const CoinBalanceCard({super.key, required this.summary, this.onTap});

  final CoinSummary summary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pending = summary.pendingReports;
    return AppCard(
      color: context.colors.amber,
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            Icons.monetization_on,
            size: 36,
            color: context.colors.amberText,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${summary.balance} coins',
                  style: TextStyle(
                    color: context.colors.amberText,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  pending == 0
                      ? 'Earned from resolved reports'
                      : '$pending open ${pending == 1 ? 'report' : 'reports'} '
                            'can earn up to ${pending * maxCoinsPerReport} more',
                  style: TextStyle(color: context.colors.amberText),
                ),
              ],
            ),
          ),
          if (onTap != null)
            Icon(Icons.chevron_right, color: context.colors.amberText),
        ],
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: context.colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(color: context.colors.muted)),
          ),
        ],
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final earned = achievement.earned;
    return Semantics(
      label:
          '${achievement.title}, ${earned ? 'earned' : 'locked'}. '
          '${achievement.description}.',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: earned ? c.amber : c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: earned ? c.amberText : c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              earned ? achievement.icon : Icons.lock_outline,
              color: earned ? c.amberText : c.muted,
            ),
            const Spacer(),
            Text(
              achievement.title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: earned ? c.amberText : c.ink,
              ),
            ),
            Text(
              achievement.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                color: earned ? c.amberText : c.muted,
              ),
            ),
            if (!earned && achievement.goal > 1) ...[
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: achievement.progress / achievement.goal,
                minHeight: 4,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
