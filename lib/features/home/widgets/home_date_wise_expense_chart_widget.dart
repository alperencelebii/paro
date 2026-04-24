import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';

import '../../../core/extensions/currency_context_extension.dart';
import '../../expense_list/bloc/expense_list_bloc.dart';
import '../../expense_list/bloc/expense_list_state.dart';
import '../../income_list/bloc/income_list_bloc.dart';
import '../../income_list/bloc/income_list_state.dart';

enum _ChartType { expense, income }

/// Compact bar chart widget showing date-wise expenses for the home screen
class HomeDateWiseExpenseChartWidget extends StatefulWidget {
  final int days;

  const HomeDateWiseExpenseChartWidget({
    super.key,
    this.days = 10,
  });

  @override
  State<HomeDateWiseExpenseChartWidget> createState() =>
      _HomeDateWiseExpenseChartWidgetState();
}

class _HomeDateWiseExpenseChartWidgetState
    extends State<HomeDateWiseExpenseChartWidget> {
  _ChartType _selected = _ChartType.expense;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpenseListBloc, ExpenseListState>(
      builder: (context, expenseState) {
        return BlocBuilder<IncomeListBloc, IncomeListState>(
          builder: (context, incomeState) {
            // Show loading while either is loading on first mount
            // final isLoading = expenseState is ExpenseListLoading ||
            //     incomeState.status == IncomeListStatus.loading;

            // if (isLoading) {
            //   return _buildLoadingState(context);
            // }

            // Build daily data from blocs
            final dailyData = _buildDailyData(
              expenseState is ExpenseListLoaded
                  ? expenseState.expenses
                  : const [],
              incomeState.status == IncomeListStatus.loaded
                  ? incomeState.incomes
                  : const [],
              days: widget.days,
            );

            final totalExpense =
                dailyData.fold<double>(0.0, (s, d) => s + d.expense);
            final totalIncome =
                dailyData.fold<double>(0.0, (s, d) => s + d.income);

            double changePercentage = 0.0;
            if (dailyData.length > 1) {
              final mid = dailyData.length ~/ 2;
              final first = dailyData.sublist(0, mid).fold<double>(
                  0.0,
                  (s, d) => _selected == _ChartType.expense
                      ? s + d.expense
                      : s + d.income);
              final second = dailyData.sublist(mid).fold<double>(
                  0.0,
                  (s, d) => _selected == _ChartType.expense
                      ? s + d.expense
                      : s + d.income);
              if (first > 0) {
                changePercentage = ((second - first) / first) * 100;
              } else if (second > 0) {
                changePercentage = 100.0;
              }
            }

            final state = _DateWiseViewState(
              dailyData: dailyData,
              totalExpense: totalExpense,
              totalIncome: totalIncome,
              changePercentage: changePercentage,
            );

            return _buildChart(context, state);
          },
        );
      },
    );
  }

  // Widget _buildLoadingState(BuildContext context) {
  //   return Container(
  //     padding: EdgeInsets.all(16.r),
  //     margin: EdgeInsets.symmetric(horizontal: 0.w, vertical: 8.h),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(16.r),
  //     ),
  //     child: const Center(
  //       child: CircularProgressIndicator(),
  //     ),
  //   );
  // }

  // Keeping an error builder here for potential future use (no-op currently)

  Widget _buildChart(BuildContext context, _DateWiseViewState state) {
    final currency = context.selectedCurrency;
    final formatter = NumberFormat.currency(
      symbol: currency.symbol,
      decimalDigits: 0,
    );

    // Calculate max value for scaling based on selection
    final maxValue = state.dailyData.isEmpty
        ? 100.0
        : state.dailyData
            .map((e) => _selected == _ChartType.expense ? e.expense : e.income)
            .reduce((a, b) => a > b ? a : b);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 0.w, vertical: 8.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with total and change
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatter.format(_selected == _ChartType.expense
                          ? state.totalExpense
                          : state.totalIncome),
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Text(
                          'Last ${widget.days} Days',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: state.changePercentage >= 0
                                ? Colors.red.shade50
                                : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            '${state.changePercentage >= 0 ? '+' : ''}${state.changePercentage.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: state.changePercentage >= 0
                                  ? Colors.red.shade700
                                  : Colors.green.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PopupMenuButton<_ChartType>(
                    initialValue: _selected,
                    onSelected: (value) {
                      setState(() => _selected = value);
                    },
                    color: Colors.white,
                    padding: EdgeInsetsGeometry.all(5.w),
                    style: ButtonStyle(
                        overlayColor:
                            const WidgetStatePropertyAll(Colors.white),
                        shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r)))),
                    surfaceTintColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r)),
                    menuPadding: EdgeInsets.all(5.w),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: _ChartType.expense,
                        child: Row(
                          children: [
                            Icon(Icons.trending_down,
                                color: const Color(0xFFF08080), size: 14.r),
                            SizedBox(width: 8.w),
                            const Text('Expense'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: _ChartType.income,
                        child: Row(
                          children: [
                            Icon(Icons.trending_up,
                                color: Colors.green, size: 14.r),
                            SizedBox(width: 8.w),
                            const Text('Income'),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _selected == _ChartType.expense
                                ? Icons.trending_down
                                : Icons.trending_up,
                            color: _selected == _ChartType.expense
                                ? const Color(0xFFF08080)
                                : Colors.green,
                            size: 16.r,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            _selected == _ChartType.expense
                                ? 'Expense'
                                : 'Income',
                            style: TextStyle(
                                fontSize: 12.sp, fontWeight: FontWeight.w600),
                          ),
                          SizedBox(width: 4.w),
                          Icon(Icons.keyboard_arrow_down_rounded, size: 16.r),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12.h),
          // Bar Chart - Reduced height to prevent overflow
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 120.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: state.dailyData.map((data) {
                final value = _selected == _ChartType.expense
                    ? data.expense
                    : data.income;
                final height = maxValue > 0 ? (value / maxValue) * 90.h : 0.0;

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 1.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Amount label above bar - smaller font to save space
                        if (value > 0)
                          Padding(
                            padding: EdgeInsets.only(bottom: 2.h),
                            child: Text(
                              formatter.format(value),
                              style: TextStyle(
                                fontSize: 7.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        // Bar
                        Flexible(
                          child: Container(
                            height: height > 0 ? height.clamp(2.0, 90.h) : 0,
                            constraints: BoxConstraints(
                              minHeight: height > 0 ? 2.h : 0,
                              maxHeight: 90.h,
                            ),
                            decoration: BoxDecoration(
                              color: _selected == _ChartType.expense
                                  ? const Color(0xFFF08080)
                                  : Colors.green.shade400,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(4.r),
                                bottom: Radius.circular(4.r),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 3.h),
                        // Date label - compact
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('MMM').format(data.date),
                              style: TextStyle(
                                fontSize: 7.sp,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              DateFormat('d').format(data.date),
                              style: TextStyle(
                                fontSize: 8.sp,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                context.pushNamed(AppRoutes.dateWiseExpense);
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'View More',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6C63FF),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateWiseViewState {
  final List<_DailyData> dailyData;
  final double totalExpense;
  final double totalIncome;
  final double changePercentage;

  _DateWiseViewState({
    required this.dailyData,
    required this.totalExpense,
    required this.totalIncome,
    required this.changePercentage,
  });
}

class _DailyData {
  final DateTime date;
  final double expense;
  final double income;

  _DailyData({
    required this.date,
    required this.expense,
    required this.income,
  });
}

List<_DailyData> _buildDailyData(List expenses, List incomes, {int days = 10}) {
  final now = DateTime.now();
  final startDate = now.subtract(Duration(days: days - 1));
  final map = <DateTime, _DailyData>{};
  for (int i = 0; i < days; i++) {
    final d = startDate.add(Duration(days: i));
    final day = DateTime(d.year, d.month, d.day);
    map[day] = _DailyData(date: day, expense: 0.0, income: 0.0);
  }
  for (final e in expenses) {
    final day = DateTime(e.date.year, e.date.month, e.date.day);
    final existing = map[day];
    if (existing != null) {
      map[day] = _DailyData(
        date: day,
        expense: existing.expense + (e.amount as double),
        income: existing.income,
      );
    }
  }
  for (final i in incomes) {
    final day = DateTime(i.date.year, i.date.month, i.date.day);
    final existing = map[day];
    if (existing != null) {
      map[day] = _DailyData(
        date: day,
        expense: existing.expense,
        income: existing.income + (i.amount as double),
      );
    }
  }
  final list = map.values.toList()..sort((a, b) => a.date.compareTo(b.date));
  return list;
}
