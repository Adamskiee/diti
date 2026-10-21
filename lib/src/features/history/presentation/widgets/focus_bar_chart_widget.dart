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

  static const _focusSegmentKey = ValueKey('focus-segment');
  static const _restSegmentKey = ValueKey('rest-segment');

  /// The bucket the user tapped, if any.
  DailyBucket? get _selectedBucket {
    final index = _selectedIdx;
    if (index == null || index >= widget.buckets.length) return null;
    return widget.buckets[index];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxDuration = widget.buckets.fold<int>(
      0,
      (max, b) => math.max(max, b.totalDurationMs),
    );
    final selectedBucket = _selectedBucket;

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
                Flexible(
                  child: Text(
                    'Focus & Rest Activity',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (selectedBucket != null)
                  Flexible(
                    child: Text(
                      _selectionReadout(selectedBucket),
                      textAlign: TextAlign.end,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
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
                      final barWidth = math.max(
                        8.0,
                        (isScrollable
                                ? 36.0
                                : constraints.maxWidth /
                                    widget.buckets.length) *
                            0.4,
                      );

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
                                child: _buildBar(
                                  bucket: bucket,
                                  ratio: ratio,
                                  isSelected: isSelected,
                                  width: barWidth,
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
            const SizedBox(height: 16),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  /// Renders one bar: the focus segment at the bottom, the rest segment
  /// above it.
  Widget _buildBar({
    required DailyBucket bucket,
    required double ratio,
    required bool isSelected,
    required double width,
  }) {
    final theme = Theme.of(context);
    final totalHeight = math.max(4.0, ratio * 100);
    final hasData = bucket.totalDurationMs > 0;
    final focusRatio = hasData
        ? math.min(1.0, bucket.focusDurationMs / bucket.totalDurationMs)
        : 0.0;
    final focusHeight = totalHeight * focusRatio;
    final restHeight = hasData ? totalHeight - focusHeight : 0.0;
    final opacity = isSelected ? 1.0 : 0.75;
    final focusColor = theme.colorScheme.primary.withValues(alpha: opacity);
    final restColor = theme.colorScheme.tertiary.withValues(alpha: opacity);

    return Container(
      width: width,
      height: totalHeight,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: hasData ? Colors.transparent : theme.colorScheme.outlineVariant,
      ),
      child: hasData
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (restHeight > 0)
                  Container(
                    key: _restSegmentKey,
                    height: restHeight,
                    color: restColor,
                  ),
                if (focusHeight > 0)
                  Container(
                    key: _focusSegmentKey,
                    height: focusHeight,
                    color: focusColor,
                  ),
              ],
            )
          : null,
    );
  }

  Widget _buildLegend() {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLegendEntry(theme.colorScheme.primary, 'Focus'),
        const SizedBox(width: 16),
        _buildLegendEntry(theme.colorScheme.tertiary, 'Rest'),
      ],
    );
  }

  Widget _buildLegendEntry(Color color, String label) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  /// The readout of the selected bucket: focus and rest on their own, or the
  /// total alone when the bucket has no rest time.
  String _selectionReadout(DailyBucket bucket) {
    if (bucket.restDurationMs > 0) {
      return '${bucket.dayLabel}: '
          '${DurationFormatter.formatMs(bucket.focusDurationMs)} focus · '
          '${DurationFormatter.formatMs(bucket.restDurationMs)} rest';
    }
    return '${bucket.dayLabel}: '
        '${DurationFormatter.formatMs(bucket.totalDurationMs)}';
  }
}
