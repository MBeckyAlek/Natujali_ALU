import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../models/report_insights.dart';
import '../../widgets/app_card.dart';
import '../../widgets/choice_pill.dart';

final _dayFormat = DateFormat('d MMM');
final _weekdayFormat = DateFormat('E');

/// Line chart of reports opened vs resolved per day, with a 7/30 day toggle.
/// If "Opened" keeps running above "Resolved", the backlog is growing.
class ActivityChart extends StatefulWidget {
  const ActivityChart({super.key, required this.insights});

  final ReportInsights insights;

  @override
  State<ActivityChart> createState() => _ActivityChartState();
}

class _ActivityChartState extends State<ActivityChart> {
  int _days = 7;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final activity = widget.insights.dailyActivity(_days);
    final opened = activity.fold(0, (sum, day) => sum + day.opened);
    final resolved = activity.fold(0, (sum, day) => sum + day.resolved);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Opened vs resolved',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              for (final days in const [7, 30])
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: ChoicePill(
                    label: '${days}d',
                    selected: days == _days,
                    onTap: () => setState(() => _days = days),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _LegendItem(color: c.chartOpened, label: 'Opened ($opened)'),
              const SizedBox(width: 16),
              _LegendItem(
                color: c.chartResolved,
                label: 'Resolved ($resolved)',
                dashed: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Semantics(
            label:
                'Last $_days days: $opened reports opened, $resolved resolved.',
            child: SizedBox(height: 180, child: _chart(context, activity)),
          ),
        ],
      ),
    );
  }

  Widget _chart(BuildContext context, List<DayActivity> activity) {
    final c = context.colors;
    final peak = activity.fold(
      0,
      (most, day) => math.max(most, math.max(day.opened, day.resolved)),
    );
    // Whole-number steps, with a little headroom above the highest point.
    final step = math.max(1, (peak / 4).ceil()).toDouble();
    final maxY = math.max(4, peak + 1).toDouble();
    final axisStyle = TextStyle(color: c.muted, fontSize: 11);

    LineChartBarData line(
      Color color,
      int Function(DayActivity) valueOf, {
      bool dashed = false,
    }) {
      return LineChartBarData(
        spots: [
          for (var i = 0; i < activity.length; i++)
            FlSpot(i.toDouble(), valueOf(activity[i]).toDouble()),
        ],
        color: color,
        barWidth: 2,
        // Curves read well for a week but look spiky over a month.
        isCurved: _days == 7,
        preventCurveOverShooting: true,
        dashArray: dashed ? [6, 4] : null,
        dotData: FlDotData(
          show: _days == 7,
          getDotPainter: (_, _, _, _) => FlDotCirclePainter(
            radius: 4,
            color: color,
            strokeWidth: 2,
            strokeColor: c.surface,
          ),
        ),
      );
    }

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          line(c.chartOpened, (day) => day.opened),
          line(c.chartResolved, (day) => day.resolved, dashed: true),
        ],
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: step,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: c.border, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: step,
              getTitlesWidget: (value, meta) => SideTitleWidget(
                meta: meta,
                child: Text(value.toInt().toString(), style: axisStyle),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                // Every day for a week; one label a week for 30 days.
                final show =
                    _days == 7 || (activity.length - 1 - index) % 7 == 0;
                if (!show || index < 0 || index >= activity.length) {
                  return const SizedBox.shrink();
                }
                final day = activity[index].day;
                return SideTitleWidget(
                  meta: meta,
                  // Keeps the first and last dates from being cut off.
                  fitInside: SideTitleFitInsideData.fromTitleMeta(meta),
                  child: Text(
                    _days == 7
                        ? _weekdayFormat.format(day)
                        : _dayFormat.format(day),
                    style: axisStyle,
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => c.ink,
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItems: (spots) => [
              for (final spot in spots)
                LineTooltipItem(
                  spot.barIndex == 0
                      ? '${_dayFormat.format(activity[spot.x.toInt()].day)}\n'
                            'Opened: ${spot.y.toInt()}'
                      : 'Resolved: ${spot.y.toInt()}',
                  TextStyle(color: c.surface, fontSize: 12),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    this.dashed = false,
  });

  final Color color;
  final String label;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final segment = Container(width: dashed ? 7 : 18, height: 2, color: color);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dashed) ...[
          segment,
          const SizedBox(width: 4),
          segment,
        ] else
          segment,
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: context.colors.ink, fontSize: 12)),
      ],
    );
  }
}
