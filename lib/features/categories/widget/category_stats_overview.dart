import 'package:finance_track/data/models/expense_model.dart';
import 'package:finance_track/data/models/income_model.dart';
import 'package:finance_track/features/dashboard/bloc/category_analysis_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:finance_track/core/localization/localization.dart';

/// A widget to display the stats overview for all categories
class CategoryStatsOverview extends StatelessWidget {
  final ThemeData theme;
  final CategoryAnalysisLoaded state;
  final int selectedTimeFrame;
  final bool isExpense;

  const CategoryStatsOverview({
    super.key,
    required this.theme,
    required this.state,
    required this.selectedTimeFrame,
    required this.isExpense,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
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
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isExpense ? Icons.bar_chart : Icons.trending_up,
                      color: isExpense ? theme.colorScheme.error : Colors.green,
                      size: 22.r,
                    ),
                    SizedBox(width: 10.w),
                    LocalizedText(
                      isExpense ? 'Expense Overview' : 'Income Overview',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 5.h,
                  ),
                  decoration: BoxDecoration(
                    color: isExpense
                        ? theme.colorScheme.error.withValues(alpha: 0.1)
                        : Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: isExpense
                          ? theme.colorScheme.error.withValues(alpha: 0.3)
                          : Colors.green.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: LocalizedText(
                    _getTimeFrameLabel(selectedTimeFrame),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isExpense ? theme.colorScheme.error : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Divider(
              height: 24.h,
              thickness: 1,
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
            ),
            Column(
              children: [
                _buildTotalAmountCard(theme, state, isExpense),
                SizedBox(height: 16.h),
                _buildChart(theme, state, isExpense),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalAmountCard(
    ThemeData theme,
    CategoryAnalysisLoaded state,
    bool isExpense,
  ) {
    final formatter = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );

    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: (isExpense ? theme.colorScheme.error : Colors.green)
            .withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: (isExpense ? theme.colorScheme.error : Colors.green)
              .withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: (isExpense ? theme.colorScheme.error : Colors.green)
                  .withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isExpense ? Icons.trending_down : Icons.trending_up,
              color: isExpense ? theme.colorScheme.error : Colors.green,
              size: 18.r,
            ),
          ),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LocalizedText('Total ${isExpense ? 'Expenses' : 'Income'}',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2.h),
              LocalizedText(
                formatter.format(
                  isExpense ? state.totalExpenses : state.totalIncomes,
                ),
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: isExpense ? theme.colorScheme.error : Colors.green,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: LocalizedText('${isExpense ? state.expenseCategoriesAmount.length : state.incomeCategoriesAmount.length} Categories',
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(
    ThemeData theme,
    CategoryAnalysisLoaded state,
    bool isExpense,
  ) {
    final categoriesAmount = isExpense
        ? state.expenseCategoriesAmount
        : state.incomeCategoriesAmount;
    final categoriesPercentage = isExpense
        ? state.expenseCategoriesPercentage
        : state.incomeCategoriesPercentage;

    if (categoriesAmount.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isExpense ? Icons.trending_down : Icons.trending_up,
              size: 40.r,
              color: theme.colorScheme.outline.withValues(alpha: 0.5),
            ),
            SizedBox(height: 12.h),
            LocalizedText('No data available',
              style: TextStyle(
                color: theme.colorScheme.outline,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final sortedEntries = categoriesAmount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final List<MapEntry<dynamic, double>> displayEntries = [];
    final List<Color> barColors = [];
    final List<String> categoryNames = [];
    double othersSum = 0;

    for (int i = 0; i < sortedEntries.length; i++) {
      if (i < 5) {
        displayEntries.add(sortedEntries[i]);

        final category = sortedEntries[i].key;
        if (category is String) {
          barColors.add(isExpense ? theme.colorScheme.error : Colors.green);
          categoryNames.add(category);
        } else if (isExpense) {
          final expenseCategory = category as ExpenseCategory;
          barColors.add(expenseCategory.color);
          categoryNames.add(expenseCategory.displayName.split(' ')[0]);
        } else {
          final incomeCategory = category as IncomeCategory;
          barColors.add(incomeCategory.color);
          categoryNames.add(incomeCategory.displayName.split(' ')[0]);
        }
      } else {
        othersSum += sortedEntries[i].value;
      }
    }

    if (othersSum > 0) {
      displayEntries.add(MapEntry('Others', othersSum));
      barColors.add(theme.colorScheme.outline);
      categoryNames.add('Others');
    }

    return Column(
      children: [
        Expanded(
          child: BarChart(
            BarChartData(
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  // backgroundColor: theme.colorScheme.surface,

                  tooltipBorderRadius: BorderRadius.circular(8.r),
                  tooltipPadding: EdgeInsets.all(12.r),
                  tooltipMargin: 8.r,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final category = categoryNames[groupIndex];
                    final percentage =
                        (categoriesPercentage[displayEntries[groupIndex].key] ??
                                0)
                            .toStringAsFixed(1);
                    final amount = NumberFormat.currency(
                      symbol: '\$',
                      decimalDigits: 2,
                    ).format(displayEntries[groupIndex].value);

                    return BarTooltipItem(
                      '$category\n',
                      TextStyle(
                        color: barColors[groupIndex],
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                      children: [
                        TextSpan(
                          text: '$amount\n',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text: AppLocalizations.tr('$percentage% of total'),
                          style: TextStyle(
                            color: barColors[groupIndex],
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                touchCallback: (FlTouchEvent event, barTouchResponse) {},
                handleBuiltInTouches: true,
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: false,
                    getTitlesWidget: (value, meta) => const SizedBox.shrink(),
                  ),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                show: true,
                horizontalInterval: 25,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color:
                        theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
                    strokeWidth: 1,
                    dashArray: value > 0 ? [3, 3] : null,
                  );
                },
                drawVerticalLine: false,
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(
                displayEntries.length,
                (index) {
                  final entry = displayEntries[index];
                  final percentage = categoriesPercentage[entry.key] ?? 0.0;

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: percentage,
                        color: barColors[index],
                        width: 20.w,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(6.r)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: 100,
                          color: barColors[index].withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  );
                },
              ),
              maxY: 100,
              minY: 0,
              alignment: BarChartAlignment.spaceAround,
              groupsSpace: 20.w,
            ),
            swapAnimationDuration: const Duration(milliseconds: 500),
            swapAnimationCurve: Curves.easeInOutCubic,
          ),
        ),
        SizedBox(height: 16.h),
        _buildCategoryLegend(
          barColors,
          categoryNames,
          theme,
          categoriesPercentage,
          displayEntries,
        ),
      ],
    );
  }

  Widget _buildCategoryLegend(
    List<Color> colors,
    List<String> names,
    ThemeData theme,
    Map<dynamic, double> categoriesPercentage,
    List<MapEntry<dynamic, double>> displayEntries,
  ) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10.w,
      runSpacing: 8.h,
      children: List.generate(
        colors.length,
        (index) => Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: colors[index].withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: colors[index].withValues(alpha: 0.1),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8.r,
                height: 8.r,
                decoration: BoxDecoration(
                  color: colors[index],
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 4.w),
              LocalizedText(
                names[index],
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 4.w),
              LocalizedText('(${(categoriesPercentage[displayEntries[index].key] ?? 0).toStringAsFixed(1)}%)',
                style: TextStyle(
                  color: colors[index],
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeFrameLabel(int days) {
    switch (days) {
      case 7:
        return 'Last 7 days';
      case 30:
        return 'Last 30 days';
      case 90:
        return 'Last 3 months';
      case 365:
        return 'Last year';
      default:
        return 'Last $days days';
    }
  }
}
