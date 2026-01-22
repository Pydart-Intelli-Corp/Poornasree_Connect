import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../utils/utils.dart';
import '../../../models/lactosure_reading.dart';
import '../../../l10n/app_localizations.dart';

/// A legend item for the graph
class GraphLegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const GraphLegendItem({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.5), blurRadius: 4),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: context.textSecondaryColor,
          ),
        ),
      ],
    );
  }
}

/// A live trend graph card showing FAT, SNF, CLR, Water values over time
class LiveTrendGraph extends StatefulWidget {
  final List<LactosureReading> readingHistory;
  final int maxHistoryPoints;

  // Define parameter colors
  static const fatColor = Color(0xFFf59e0b);
  static const snfColor = Color(0xFF3b82f6);
  static const clrColor = Color(0xFF8b5cf6);
  static const waterColor = Color(0xFF14B8A6);

  const LiveTrendGraph({
    super.key,
    required this.readingHistory,
    this.maxHistoryPoints = 20,
  });

  @override
  State<LiveTrendGraph> createState() => _LiveTrendGraphState();
}

class _LiveTrendGraphState extends State<LiveTrendGraph> {
  int _windowOffset = 0; // 0 means showing the latest data

  @override
  void didUpdateWidget(LiveTrendGraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset to latest data when new reading arrives
    if (widget.readingHistory.length != oldWidget.readingHistory.length) {
      setState(() {
        _windowOffset = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Calculate visible window
    final totalReadings = widget.readingHistory.length;
    final endIndex = totalReadings - _windowOffset;
    final startIndex = (endIndex - widget.maxHistoryPoints).clamp(
      0,
      totalReadings,
    );
    final displayReadings = widget.readingHistory.sublist(startIndex, endIndex);

    // Check if navigation is possible
    final canGoBack =
        startIndex > 0; // Can show older data (has more data before startIndex)
    final canGoForward =
        _windowOffset > 0; // Can show newer data (not at latest)

    // Create line data for each parameter
    List<FlSpot> fatSpots = [];
    List<FlSpot> snfSpots = [];
    List<FlSpot> clrSpots = [];
    List<FlSpot> waterSpots = [];

    double maxValue = 10; // Default minimum scale

    for (int i = 0; i < displayReadings.length; i++) {
      final reading = displayReadings[i];
      fatSpots.add(FlSpot(i.toDouble(), reading.fat));
      snfSpots.add(FlSpot(i.toDouble(), reading.snf));
      clrSpots.add(FlSpot(i.toDouble(), reading.clr));
      waterSpots.add(FlSpot(i.toDouble(), reading.water));

      // Track max value for auto-scaling
      if (reading.fat > maxValue) maxValue = reading.fat;
      if (reading.snf > maxValue) maxValue = reading.snf;
      if (reading.clr > maxValue) maxValue = reading.clr;
      if (reading.water > maxValue) maxValue = reading.water;
    }

    // Round up to next nice interval (10, 20, 30, 40, 50, etc.)
    final double maxY = ((maxValue / 10).ceil() * 10).toDouble().clamp(10, 100);
    final double interval = maxY / 10;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [context.cardColor, context.surfaceColor],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Main content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Navigation and Legend row
                Row(
                  children: [
                    // Left arrow - show older data
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: canGoBack
                            ? () {
                                setState(() {
                                  _windowOffset += widget.maxHistoryPoints ~/ 2;
                                  if (_windowOffset + widget.maxHistoryPoints >
                                      totalReadings) {
                                    _windowOffset =
                                        totalReadings - widget.maxHistoryPoints;
                                  }
                                });
                              }
                            : null,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.chevron_left_rounded,
                            size: 18,
                            color: canGoBack
                                ? context.textPrimaryColor
                                : context.textSecondaryColor.withOpacity(0.3),
                          ),
                        ),
                      ),
                    ),
                    // Legend
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GraphLegendItem(
                              label: AppLocalizations().tr('fat').toUpperCase(),
                              color: LiveTrendGraph.fatColor,
                            ),
                            const SizedBox(width: 16),
                            GraphLegendItem(
                              label: AppLocalizations().tr('snf').toUpperCase(),
                              color: LiveTrendGraph.snfColor,
                            ),
                            const SizedBox(width: 16),
                            GraphLegendItem(
                              label: AppLocalizations().tr('clr').toUpperCase(),
                              color: LiveTrendGraph.clrColor,
                            ),
                            const SizedBox(width: 16),
                            GraphLegendItem(
                              label: AppLocalizations().tr('water'),
                              color: LiveTrendGraph.waterColor,
                            ),
                            if (_windowOffset > 0) ...[
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF3b82f6,
                                  ).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF3b82f6,
                                    ).withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  AppLocalizations().tr('history'),
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF3b82f6),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    // Right arrow - show newer data
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: canGoForward
                            ? () {
                                setState(() {
                                  _windowOffset -= widget.maxHistoryPoints ~/ 2;
                                  if (_windowOffset < 0) {
                                    _windowOffset = 0;
                                  }
                                });
                              }
                            : null,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: canGoForward
                                ? context.textPrimaryColor
                                : context.textSecondaryColor.withOpacity(0.3),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Graph
                Expanded(
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: interval,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: context.borderColor,
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: displayReadings.length > 10
                                ? 2
                                : 1, // Show every 2nd number if more than 10 points
                            reservedSize: 22,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              // Show mark for reading points
                              if (index >= 0 &&
                                  index < displayReadings.length) {
                                // Calculate original reading number
                                final originalIndex = startIndex + index + 1;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '$originalIndex',
                                    style: TextStyle(
                                      color: context.textSecondaryColor,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: interval,
                            reservedSize: 32,
                            getTitlesWidget: (value, meta) => Text(
                              value.toInt().toString(),
                              style: TextStyle(
                                color: context.textSecondaryColor,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: (displayReadings.length - 1).toDouble().clamp(
                        0,
                        widget.maxHistoryPoints.toDouble() - 1,
                      ),
                      minY: 0,
                      maxY: maxY,
                      lineBarsData: [
                        _buildLineChartBarData(
                          fatSpots,
                          LiveTrendGraph.fatColor,
                        ),
                        _buildLineChartBarData(
                          snfSpots,
                          LiveTrendGraph.snfColor,
                        ),
                        _buildLineChartBarData(
                          clrSpots,
                          LiveTrendGraph.clrColor,
                        ),
                        _buildLineChartBarData(
                          waterSpots,
                          LiveTrendGraph.waterColor,
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        enabled: true,
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (touchedSpot) =>
                              context.cardColor,
                          tooltipBorder: BorderSide(
                            color: context.borderColor,
                          ),
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              String label = '';
                              double actualValue = spot.y;
                              if (spot.barIndex == 0) {
                                label = AppLocalizations()
                                    .tr('fat')
                                    .toUpperCase();
                              } else if (spot.barIndex == 1) {
                                label = AppLocalizations()
                                    .tr('snf')
                                    .toUpperCase();
                              } else if (spot.barIndex == 2) {
                                label = AppLocalizations()
                                    .tr('clr')
                                    .toUpperCase();
                              } else if (spot.barIndex == 3) {
                                label = AppLocalizations().tr('water');
                              }
                              return LineTooltipItem(
                                '$label: ${actualValue.toStringAsFixed(2)}',
                                TextStyle(
                                  color: spot.bar.color,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  LineChartBarData _buildLineChartBarData(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          // Only show dot for the last point (latest reading)
          if (index == spots.length - 1) {
            return FlDotCirclePainter(
              radius: 4,
              color: color,
              strokeWidth: 2,
              strokeColor: Colors.white,
            );
          }
          return FlDotCirclePainter(
            radius: 0,
            color: Colors.transparent,
            strokeWidth: 0,
            strokeColor: Colors.transparent,
          );
        },
      ),
      belowBarData: BarAreaData(show: true, color: color.withOpacity(0.1)),
    );
  }
}
