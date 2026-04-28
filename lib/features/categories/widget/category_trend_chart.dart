import 'package:finance_track/core/models/currency_model.dart';
import 'package:finance_track/features/monthly_summary/models/transaction_item.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:finance_track/core/localization/localization.dart';

/// A widget to display a single summary item

/// A widget to display the trend chart for a category
class CategoryTrendChart extends StatelessWidget {
  final List<TransactionItem> periodicData;
  final Color categoryColor;
  final Currency currency;
  final DateTimeRange dateRange;

  const CategoryTrendChart({
    super.key,
    required this.periodicData,
    required this.categoryColor,
    required this.currency,
    required this.dateRange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (periodicData.isEmpty) {
      return _buildEmptyState(theme);
    }

    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LocalizedText('Spending Trend',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 24.h),
          SizedBox(
            height: 200.h,
            child: _buildChart(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32.h),
          child: Column(
            children: [
              Icon(
                Icons.timeline,
                size: 48.r,
                color: Colors.grey.withValues(alpha: 0.5),
              ),
              SizedBox(height: 16.h),
              LocalizedText('No data available for selected period',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChart(ThemeData theme) {
    final formatter = NumberFormat.currency(
      symbol: currency.symbol,
      decimalDigits: 2,
    );

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: theme.dividerColor.withValues(alpha: 0.3),
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < periodicData.length) {
                  final dateFormat = periodicData.length > 10
                      ? DateFormat('d')
                      : DateFormat('MMM d');
                  return Padding(
                    padding: EdgeInsets.only(top: 8.h),
                    child: LocalizedText(
                      dateFormat.format(periodicData[value.toInt()].date),
                      style: theme.textTheme.bodySmall,
                    ),
                  );
                }
                return const SizedBox();
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: LocalizedText(
                    formatter.format(value),
                    style: theme.textTheme.bodySmall,
                  ),
                );
              },
              reservedSize: 40,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              periodicData.length,
              (index) => FlSpot(
                index.toDouble(),
                periodicData[index].amount,
              ),
            ),
            isCurved: true,
            color: categoryColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: categoryColor,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: categoryColor.withValues(alpha: 0.2),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            // tooltipBgColor: theme.colorScheme.surface.withValues(alpha:0.8),
            tooltipBorderRadius: BorderRadius.circular(8.r),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                if (index >= 0 && index < periodicData.length) {
                  final data = periodicData[index];
                  return LineTooltipItem(
                    '${DateFormat('MMM d').format(data.date)}\n${formatter.format(data.amount)}',
                    TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }
                return null;
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}
