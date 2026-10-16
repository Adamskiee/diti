import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/utils/duration_formatter.dart';
import '../../domain/analytics_models.dart';

class FocusBarChartWidget extends StatefulWidget {
  final List<DailyBucket> buckets;
  final ValueChanged<DailyBucket>? onBucketSelected;

  const FocusBarChartWidget({
    super.key,
    required this.buckets,
    this.onBucketSelected,
  });

  @override
  State<FocusBarChartWidget> createState() => _FocusBarChartWidgetState();
}

class _FocusBarChartWidgetState extends State<FocusBarChartWidget> {
  int? _selectedIdx;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxDuration = widget.buckets.fold<int>(
      0,
      (max, b) => math.max(max, b.totalDurationMs),
    );

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Focus Activity',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_selectedIdx != null && _selectedIdx! < widget.buckets.length)
                  Text(
                    '${widget.buckets[_selectedIdx!].dayLabel}: ${DurationFormatter.formatMs(widget.buckets[_selectedIdx!].totalDurationMs)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 140,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isScrollable = widget.buckets.length > 7;
                  final content = Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: isScrollable
                        ? MainAxisAlignment.start
                        : MainAxisAlignment.spaceEvenly,
                    children: List.generate(widget.buckets.length, (index) {
                      final bucket = widget.buckets[index];
                      final ratio = maxDuration > 0
                          ? bucket.totalDurationMs / maxDuration
                          : 0.0;
                      final isSelected = _selectedIdx == index;

                      final columnWidget = InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          setState(() {
                            _selectedIdx = isSelected ? null : index;
                          });
                          widget.onBucketSelected?.call(bucket);
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  width: math.max(
                                    8.0,
                                    (isScrollable
                                            ? 36.0
                                            : constraints.maxWidth /
                                                widget.buckets.length) *
                                        0.4,
                                  ),
                                  height: math.max(4.0, ratio * 100),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : (bucket.totalDurationMs > 0
                                            ? theme.colorScheme.primary
                                                .withValues(alpha: 0.75)
                                            : theme.colorScheme.outlineVariant),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              bucket.dayLabel,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      );

                      if (isScrollable) {
                        return SizedBox(width: 36, child: columnWidget);
                      }
                      return Expanded(child: columnWidget);
                    }),
                  );

                  if (isScrollable) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: content,
                    );
                  }
                  return content;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
