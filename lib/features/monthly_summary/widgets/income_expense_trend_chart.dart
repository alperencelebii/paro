import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:finance_track/core/localization/localization.dart';

class IncomeExpenseTrendChart extends StatelessWidget {
  final Map<DateTime, double> dailyExpenses;
  final Map<DateTime, double> dailyIncomes;
  final String currencySymbol;

  const IncomeExpenseTrendChart({
    super.key,
    required this.dailyExpenses,
    required this.dailyIncomes,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (dailyExpenses.isEmpty && dailyIncomes.isEmpty) {
      return _buildEmptyState(context);
    }

    // Combine both maps to get all unique dates
    final allDates = <DateTime>{};
    allDates.addAll(dailyExpenses.keys);
    allDates.addAll(dailyIncomes.keys);

    final sortedDates = allDates.toList()..sort((a, b) => a.compareTo(b));

    // Find max amount for Y-axis scaling
    final maxExpense = dailyExpenses.isEmpty
        ? 0.0
        : dailyExpenses.values
            .reduce((max, value) => value > max ? value : max);
    final maxIncome = dailyIncomes.isEmpty
        ? 0.0
        : dailyIncomes.values.reduce((max, value) => value > max ? value : max);
    final maxAmount = [maxExpense, maxIncome]
        .reduce((max, value) => value > max ? value : max);

    // Calculate Y-axis intervals
    final yInterval = _calculateYAxisInterval(maxAmount);
    final maxY = ((maxAmount ~/ yInterval) + 1) * yInterval.toDouble();

    // Map dates to sequential indices for x-axis
    final datesIndices = <DateTime, int>{};
    for (int i = 0; i < sortedDates.length; i++) {
      datesIndices[sortedDates[i]] = i;
    }

    // Create spots for income and expense line charts
    final expenseSpots = <FlSpot>[];
    final incomeSpots = <FlSpot>[];

    for (final date in sortedDates) {
      final index = datesIndices[date]!.toDouble();

      // Add expense spot if exists for this date
      if (dailyExpenses.containsKey(date)) {
        expenseSpots.add(FlSpot(index, dailyExpenses[date]!));
      }

      // Add income spot if exists for this date
      if (dailyIncomes.containsKey(date)) {
        incomeSpots.add(FlSpot(index, dailyIncomes[date]!));
      }
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, 4),
            blurRadius: 20,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.analytics_outlined,
                        color: theme.colorScheme.primary,
                        size: 22.r,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    LocalizedText('Income vs Expense',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 18.sp,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8.h),

            // Legend
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem(context, Colors.green.shade600, 'Income'),
                  SizedBox(width: 24.w),
                  _buildLegendItem(
                      context, Colors.redAccent.shade700, 'Expense'),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Chart Section
            SizedBox(
              height: 240.h,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: yInterval,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: theme.dividerColor.withValues(alpha: 0.2),
                        strokeWidth: 1,
                        dashArray: [5, 5],
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: yInterval,
                        reservedSize: 45,
                        getTitlesWidget: (value, meta) {
                          return LocalizedText(
                            value >= 1000
                                ? '$currencySymbol${(value / 1000).toStringAsFixed(0)}K'
                                : '$currencySymbol${value.toStringAsFixed(0)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withValues(alpha: 0.7),
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: sortedDates.length > 10 ? 2 : 1,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= sortedDates.length) {
                            return const SizedBox.shrink();
                          }
                          final date = sortedDates[value.toInt()];
                          return Padding(
                            padding: EdgeInsets.only(top: 8.h),
                            child: LocalizedText(
                              date.day.toString(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodySmall?.color
                                    ?.withValues(alpha: 0.7),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: sortedDates.length.toDouble() - 1,
                  minY: 0,
                  maxY: maxY,
                  lineBarsData: [
                    // Income Line
                    LineChartBarData(
                      spots: incomeSpots,
                      isCurved: true,
                      color: Colors.green.shade600,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.green.shade600,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withValues(alpha: 0.1),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.green.shade300.withValues(alpha: 0.2),
                            Colors.green.shade50.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),

                    // Expense Line
                    LineChartBarData(
                      spots: expenseSpots,
                      isCurved: true,
                      color: Colors.redAccent.shade700,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.redAccent.shade700,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.redAccent.withValues(alpha: 0.1),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.redAccent.shade100.withValues(alpha: 0.2),
                            Colors.redAccent.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      // tooltipBgColor: theme.colorScheme.surface,
                      tooltipBorderRadius: BorderRadius.circular(8.r),
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final date = sortedDates[spot.x.toInt()];
                          final isIncome = spot.barIndex == 0;

                          return LineTooltipItem(
                            '${DateFormat('MMM d').format(date)}\n',
                            TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.normal,
                            ),
                            children: [
                              TextSpan(
                                text:
                                    '$currencySymbol${spot.y.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: isIncome
                                      ? Colors.green.shade600
                                      : Colors.redAccent.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),

            // Summary section
            SizedBox(height: 16.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      context,
                      'Average Income',
                      dailyIncomes.isEmpty
                          ? 0
                          : dailyIncomes.values.reduce((a, b) => a + b) /
                              dailyIncomes.length,
                      Colors.green.shade600,
                      currencySymbol,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: _buildSummaryCard(
                      context,
                      'Average Expense',
                      dailyExpenses.isEmpty
                          ? 0
                          : dailyExpenses.values.reduce((a, b) => a + b) /
                              dailyExpenses.length,
                      Colors.redAccent.shade700,
                      currencySymbol,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12.r,
          height: 12.r,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 8.w),
        LocalizedText(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    double amount,
    Color color,
    String currencySymbol,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LocalizedText(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
          ),
          SizedBox(height: 4.h),
          LocalizedText('$currencySymbol${amount.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, 4),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 48.r,
            color: theme.colorScheme.primary.withValues(alpha: 0.5),
          ),
          SizedBox(height: 16.h),
          LocalizedText('No data available',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          LocalizedText('Add income and expenses to see the comparison trend',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateYAxisInterval(double maxValue) {
    if (maxValue <= 0) return 100;
    if (maxValue <= 100) return 20;
    if (maxValue <= 500) return 100;
    if (maxValue <= 1000) return 200;
    if (maxValue <= 5000) return 1000;
    if (maxValue <= 10000) return 2000;
    if (maxValue <= 50000) return 10000;
    if (maxValue <= 100000) return 20000;
    return 50000;
  }
}
